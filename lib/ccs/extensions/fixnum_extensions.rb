module CCS
  module FixnumExtensions
    refine Fixnum do
      def at_least(other)
        self < other ? other : self
      end

      def at_most(other)
        self > other ? other : self
      end
    end
  end
end
