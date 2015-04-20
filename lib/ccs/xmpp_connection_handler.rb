module CCS
  class XMPPConnectionHandler
    def initialize(count = 1)
      return if count <= 0
      requeue
      @supervisor = XMPPConnection.supervise(next_connection_number, self)
      (count - 1).times do
        add_connection
      end
    end

    def drain
      add_connection
    end

    def add_connection
      @supervisor.add(XMPPConnection, args: [next_connection_number, self])
    end

    def remove_connection(id)
      RedisHelper.srem(CONNECTIONS, id)
    end

    def next_connection_number
      (1..100).each do |n|
        return n if RedisHelper.sadd(CONNECTIONS, n)
      end
      nil
    end

    private

    def requeue
      prev = RedisHelper.smembers(CONNECTIONS)
      prev.each do |n|
        RedisHelper.merge_and_delete("#{XMPP_QUEUE}_#{n}", XMPP_QUEUE)
      end
      RedisHelper.del(CONNECTIONS)
    end
  end
end
