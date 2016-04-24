module CCS
  class API
    def self.send(sender_id, to, data = {}, options = {})
      msg = Notification.new(sender_id, to, data, options)
      redis.lpush(CCS.queue_for(sender_id, :ccs_queue), msg.to_json)
      msg.id
    end

    def self.redis
      @redis ||= ::Redis.new(CCS.config.redis)
    end
  end
end
