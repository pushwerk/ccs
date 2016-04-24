module CCS
  class Handler
    include Celluloid

    def initialize(sender_id)
      @redis = ::Redis.new(CCS.config.redis)
      @sender_id = sender_id
      @upstream_queue = CCS.queue_for(@sender_id, :upstream_queue).freeze
      @receipt_queue = CCS.queue_for(@sender_id, :receipt_queue).freeze
      @ccs_error = CCS.queue_for(@sender_id, :ccs_error).freeze
      @callbacks = {}
    end

    def start!
      run
    end

    def start
      async.run
    end

    def on_receipt(&block)
      @callbacks[:receipt] = block
    end

    def on_error(&block)
      @callbacks[:error] = block
    end

    def on_upstream(&block)
      @callbacks[:upstream] = block
    end

    private

    def run
      loop do
        begin
          list, value = @redis.blpop(upstream_queue, ccs_error, receipt_queue, 0)
          msg = JSON(value)
          @callbacks[list].call(msg) if @callbacks[list]
        rescue => e
          CCS.error e.inspect
        end
      end
    end
  end
end
