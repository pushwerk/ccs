require 'monitor'

module CCS
  class Semaphore
    def initialize(max = 100)
      @max = max
      @current = 0
      @con = Celluloid::Condition.new
    end

    def take
      return if @con.wait if @current == @max
      @current += 1
    end

    def release
      @con.signal(false) if @current == @max
      @current -= 1
    end

    def interrupt
      @con.signal(true)
    end
  end
end
