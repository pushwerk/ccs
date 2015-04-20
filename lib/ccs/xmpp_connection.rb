module CCS
  class XMPPConnection < XMPPSimple::Api
    include Celluloid::IO

    def initialize(id, handler)
      @id = id
      @state = :disconnected
      @draining = false
      @handler = handler
      reset

      XMPPSimple.logger = CCS.logger
      @xmpp_client = XMPPSimple::Client.new(Actor.current,
                                            CCS.configuration.sender_id,
                                            CCS.configuration.api_key,
                                            CCS.configuration.host,
                                            CCS.configuration.port).connect
    end

    def sender_loop
      redis = RedisHelper.connection(:celluloid)
      while @state == :connected && !@draining
        next unless @semaphore.take
        msg_str = redis.brpoplpush(XMPP_QUEUE, "#{XMPP_QUEUE}_#{@id}")
        msg = Oj.load(msg_str)
        send_stanza(msg)
        @send_messages[msg['message_id']] = msg_str
      end
    end

    def ack(msg)
      CCS.debug("Ack: #{msg}")
      content = {}
      content['to']           = msg['from']
      content['message_id']   = msg['message_id']
      content['message_type'] = 'ack'
      send_stanza(content)
    end

    def send_stanza(content)
      msg  = '<message>'
      msg += '<gcm xmlns="google:mobile:data">'
      msg += Oj.dump(content)
      msg += '</gcm>'
      msg += '</message>'
      CCS.debug "Write: #{msg}"
      @xmpp_client.write_data(msg)
    end

    def drain
      @handler.drain
      @draining = true
      @semaphore.interrupt
    end

    def reset
      @send_messages = {}
      @semaphore = Semaphore.new(MAX_MESSAGES)

      RedisHelper.merge_and_delete("#{XMPP_QUEUE}_#{@id}", XMPP_QUEUE)
    end

    def reconnecting
      CCS.debug('Reconnecting')
      @state = :reconnecting
      reset
    end

    def connected
      CCS.debug('Connected')
      @state = :connected
      async.sender_loop
    end

    def disconnected
      CCS.debug('Disconnected')
      @state = :disconnected
      @semaphore.interrupt
    end

    def message(node)
      xml = Ox.parse(node)
      plain_content = xml.locate('gcm/^Text').first
      content = Oj.load(plain_content)
      if xml['type'] == 'error'
        # Should not happen
      end

      return if content.nil?
      CCS.debug("Type: #{content['message_type']}")
      case content['message_type']
      when nil
        CCS.debug('Received upstream message')
        # upstream
        RedisHelper.rpush(UPSTREAM_QUEUE, Oj.dump(content))
        ack(content)
      when 'ack'
        handle_ack(content)
      when 'nack'
        handle_nack(content)
      when 'receipt'
        handle_receipt(content)
      when 'control'
        handle_control(content)
      else
        CCS.info("Received unknown message type: #{content['message_type']}")
      end
    end

    private

    def handle_receipt(content)
      CCS.debug("Delivery receipt received for: #{content['message_id']}")
      RedisHelper.rpush(RECEIPT_QUEUE, Oj.dump(content))
      ack(content)
    end

    def handle_ack(content)
      msg = @send_messages.delete(content['message_id'])
      if msg.nil?
        CCS.info("Received ack for unknown message: #{content['message_id']}")
      else
        msg.delete('message_id')
        if RedisHelper.lrem("#{XMPP_QUEUE}_#{@id}", -1, msg) < 1
          CCS.debug("NOT FOUND: #{Oj.dump(msg)}")
        end
        @semaphore.release
      end
    end

    def handle_nack(content)
      msg = @send_messages.delete(content['message_id'])
      if msg.nil?
        CCS.info("Received nack for unknown message: #{content['message_id']}")
      else
        msg.delete('message_id')
        RedisHelper.lrem("#{XMPP_QUEUE}_#{@id}", -1, msg)
        RedisHelper.rpush(XMPP_ERROR_QUEUE, Oj.dump(msg))
      end
    end

    def handle_control(content)
      case content['control_type']
      when 'CONNECTION_DRAINING'
        drain
      else
        CCS.info("Received unknown control type: #{content['control_type']}")
      end
    end
  end
end
