module CCS
  class CallbackHandler
    include Celluloid

    def initialize
      @redis = RedisHelper.connection(:celluloid)
      async.run
    end

    def run
      loop do
        begin
          list, value = @redis.blpop(UPSTREAM_QUEUE, XMPP_ERROR_QUEUE, RECEIPT_QUEUE, 0)
          msg = Oj.load(value)
          case list
          when UPSTREAM_QUEUE
            CCS.callback[:upstream].call(msg) unless CCS.callback[:upstream].nil?
          when XMPP_ERROR_QUEUE
            CCS.callback[:error].call(msg) unless CCS.callback[:error].nil?
          when RECEIPT_QUEUE
            CCS.callback[:receipt].call(msg) unless CCS.callback[:receipt].nil?
          end
        rescue => e
          CCS.error e.inspect
        end
      end
    end
  end
end
