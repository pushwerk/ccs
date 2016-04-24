require 'monitor'

module CCS
  class Semaphore
    def initialize(max = MAX_MESSAGES)
      @max = max
      @current = 0
      @condition = Celluloid::Condition.new
    end

    def take
      return if @current == @max && @condition.wait
      @current += 1
    end

    def release
      @condition.signal(false) if @current == @max
      @current -= 1
    end

    def interrupt
      @condition.signal(true)
    end
  end
end
