module Hyperstack
  module Record
    class DummyValue
      def intialize(type_class)
        @backing_value = type_class.new
      end

      def method_missing(name, *args)
        if args
          @backing_value.send(name, args)
        else
          @backing_value.send(name)
        end
      end

      def is_dummy?
        true
      end

      def acts_as_string?
        true
      end

      def to_i
        0
      end

      def to_s
        ""
      end
    end
  end
end
