module CCS
  class XMPPConnection
    include Celluloid::IO
    finalizer :close_sender

    def initialize(params = {})
      @config = CCS.config.connection(params[:sender_id])
      @id = params[:id]
      @handler = params[:handler]
      @running = false

      @send_messages = {}
      @semaphore = Semaphore.new(MAX_MESSAGES)

      @queue = @handler.connection_queue(@id)
      open_xmpp
    end

    def redis
      @redis ||= ::Redis.new(CCS.config.redis)
    end

    def open_xmpp
      xmpp_params = {
        handler: Actor.current,
        username: "#{@config['sender_id']}@gcm.googleapis.com",
        password: @config['api_key'],
        host: CCS.config.endpoint['host'],
        port: CCS.config.endpoint['port']
      }
      @xmpp_client = XMPPSimple::Client.new(xmpp_params).connect
    end

    def sender_loop
      while @running
        next unless @semaphore.take
        msg_str = redis.brpoplpush(@handler.queues[:ccs_queue], @handler.queues[:connection])
        msg = JSON(msg_str)
        send_stanza(msg)
        @send_messages[msg['message_id']] = msg_str
      end
    end

    def ack(msg)
      CCS.logger.debug("Ack: #{msg}")
      send_stanza('to' => msg['from'],
                  'message_id' => msg['message_id'],
                  'message_type' => 'ack'
                 )
    end

    def send_stanza(content = {})
      msg  = '<message><gcm xmlns="google:mobile:data">'
      msg += content.to_json
      msg += '</gcm></message>'
      CCS.logger.debug "Write: #{msg}"
      @xmpp_client.write_data(msg)
    end

    def drain
      close_sender
      @handler.drain(@id)
    end

    def close_sender
      @running = false
      @semaphore.interrupt
    end

    def connected
      CCS.logger.debug('Connected')
      @running = true
      async.sender_loop
    end

    def disconnected
      CCS.logger.debug('Disconnected')
      @handler.close_connection(@id)
    end

    def message(node)
      xml = Nokogiri::XML(node).remove_namespaces!
      content = JSON(xml.xpath('.//gcm').text)

      type = xml.xpath('//message').attribute('type')
      if type && type.value == 'error'
        handle_xml_error(node)
        return
      end
      return if content.nil? # discard empty messages
      CCS.logger.debug("Type: #{content['message_type']}")

      content['received_at'] = Time.now.utc.to_i
      content['message_type'] ||= 'upstream'
      if %w(ack nack receipt control upstream).include?(content['message_type'])
        CCS.debug("Received #{content['message_type']} message")
        send("handle_#{content['message_type']}")
      else
        CCS.logger.info("Received unknown message type: #{content['message_type']}")
      end
    end

    def handle_xml_error(node)
      # TODO:
      # This shouldn't happen
      # but could be implemented, just to be save
    end

    def handle_receipt(content)
      CCS.logger.debug("Delivery receipt received for: #{content['message_id']}")
      redis.rpush(@handler.queues[:receipt_queue], content.to_s)
      ack(content)
    end

    def handle_ack(content)
      msg = @send_messages.delete(content['message_id'])
      if msg.nil?
        CCS.logger.info("Received ack for unknown message: #{content['message_id']}")
        return
      end
      CCS.logger.debug("NOT FOUND: #{msg}") if redis.lrem(@queue, -1, msg) < 1
      @semaphore.release
    end

    def handle_nack(content)
      msg = @send_messages.delete(content['message_id'])
      if msg.nil?
        CCS.info("Received nack for unknown message: #{content['message_id']}")
        return
      end
      redis.lrem(@queue, -1, msg)
      redis.rpush(@handler.queues[:ccs_error], msg.to_s)
      @semaphore.release
    end

    def handle_control(content)
      CCS.debug.info("Received control type: #{content['control_type']}")
      drain if content['control_type'] == 'CONNECTION_DRAINING'
    end

    def handle_upstream(content)
      redis.rpush(@handler.queues[:upstream_queue], content.to_s)
      ack(content)
    end
  end
end
