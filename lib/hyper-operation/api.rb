module Hyperloop
  class Operation

    def add_error(key, kind, message = nil)
      raise ArgumentError.new("Invalid kind") unless kind.is_a?(Symbol)

      @errors ||= Mutations::ErrorHash.new
      @errors.tap do |errs|
        path = key.to_s.split(".")
        last = path.pop
        inner = path.inject(errs) do |cur_errors,part|
          cur_errors[part.to_sym] ||= Mutations::ErrorHash.new
        end
        inner[last] = Mutations::ErrorAtom.new(key, kind, :message => message)
      end
    end

    def has_errors?
      !@errors.nil?
    end

    def params
      @params
    end

    def abort!(*args)
      Railway.abort!(args)
    end

    def succeed!(*args)
      Railway.succeed!(args)
    end

    def initialize
      @_railway = self.class._Railway.new(self)
    end

    class << self

      def run(*args)
        new.instance_eval do
          @_railway.process_params(args)
          @_railway.process_validations
          @_railway.run
          @_railway.dispatch
          @_railway.result
        end
      end

      def param(*args, &block)
        _Railway.add_param(*args)
      end

      def outbound(*keys)
        keys.each { |key| _Railway.add_param(key => nil, :type => :outbound) }
      end

      def validate(*args, &block)
        _Railway.add_validation(*args, block)
      end

      def add_error(param, symbol, message, *args, &block)
        _Railway.add_error(param, symbol, message, *args, block)
      end

      def step(*args, &block)
        _Railway.add_step(*args, block)
      end

      def failed(*args, &block)
        _Railway.add_failed(*args, block)
      end

      def async(*args, &block)
        _Railway.add_async(*args, block)
      end

      def on_dispatch(&block)
        _Railway.add_receiver(block)
      end
    end
  end
end
