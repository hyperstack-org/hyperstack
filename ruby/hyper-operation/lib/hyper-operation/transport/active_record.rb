module ActiveRecord
  class Base

    class << self

      def do_not_synchronize
        @do_not_synchronize = true
      end

      def do_not_synchronize?
        @do_not_synchronize
      end
    end
  end
end
