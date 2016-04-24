module CCS
  module RedisExtensions
    refine ::Redis do
      def merge_and_delete(source, destination)
        messages = lrange(source, 0, -1)
        pipelined do
          rpush(destination, messages) unless messages.empty?
          del(source)
        end
      end
    end
  end
end
