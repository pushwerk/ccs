module CCS
  class ConnectionHandler
    include Celluloid

    using RedisExtensions
    using FixnumExtensions

    def initialize(sender_id)
      @sender_id = sender_id
      @supervisor = Celluloid::Supervision::Container.new
      @config = CCS.config.connection(sender_id)
      @redis = ::Redis.new(CCS.config.redis)
      @mutex = Mutex.new
      @connection_ids = []

      requeue_all
      add_connection(@config['connection_count'].to_i.at_least(1).at_most(1_000))
      @supervisor.class.run!
    end

    def drain
      add_connection(1)
    end

    def remove_connection(id)
      @mutex.synchronize do
        @connection_ids.delete(id)
        requeue(id)
      end
    end

    def add_connection(count = 1)
      count.times do
        number = next_connection_number
        if number.nil?
          CCS.logger.info('no free connection numbers')
          return
        end
        @supervisor.add(type: XMPPConnection, as: "xmpp_#{number}", args: [{ id: number, sender_id: @sender_id, handler: Actor.current }])
      end
    end

    def close_connection(id)
      Actor["xmpp_#{id}"].terminate if Actor["xmpp_#{id}"]
      remove_connection(id)
      add_connection(1)
    end

    def next_connection_number
      @mutex.synchronize do
        MAX_CONNECTIONS.times do |n|
          next if @connection_ids.include?(n)
          @connection_ids << n
          return n
        end
      end
      nil
    end

    def queues
      CCS.queues(@sender_id)
    end

    def connection_queue(connection_id)
      "#{queues[:ccs_queue]}_#{connection_id}".freeze
    end

    private

    def requeue_all
      MAX_CONNECTIONS.times do |n|
        requeue(n)
      end
    end

    def requeue(id)
      @redis.merge_and_delete(connection_queue(id), queues[:ccs_queue])
    end
  end
end
