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

    def abort!(arg = nil)
      Railway.abort!(arg)
    end

    def succeed!(arg = nil)
      Railway.succeed!(arg)
    end

    def initialize
      @_railway = self.class._Railway.new(self)
    end

    class << self

      def run(*args)
        _run(*args)
      end

      def _run(*args)
        new.instance_eval do
          @_railway.process_params(args)
          @_railway.process_validations
          @_railway.run
          @_railway.dispatch
          @_railway.result
        end
      end

      def then(*args, &block)
        run(*args).then(&block)
      end

      def fail(*args, &block)
        run(*args).fail(&block)
      end

      def param(*args, &block)
        _Railway.add_param(*args, &block)
      end

      def inbound(*args, &block)
        name, opts = ParamsWrapper.get_name_and_opts(*args)
        _Railway.add_param(name, opts.merge(inbound: :true), &block)
      end

      def outbound(*keys)
        keys.each { |key| _Railway.add_param(key => nil, :type => :outbound) }
        #singleton_class.outbound(*keys)
      end

      def validate(*args, &block)
        _Railway.add_validation(*args, &block)
      end

      def add_error(param, symbol, message, *args, &block)
        _Railway.add_error(param, symbol, message, *args, &block)
      end

      def step(*args, &block)
        _Railway.add_step(*args, &block)
      end

      def failed(*args, &block)
        _Railway.add_failed(*args, &block)
      end

      def async(*args, &block)
        _Railway.add_async(*args, &block)
      end

      def on_dispatch(&block)
        _Railway.add_receiver(&block)
      end

      def _Railway
        self.singleton_class._Railway
      end

      def inherited(child)

        child.singleton_class.define_singleton_method(:param) do |*args, &block|
          _Railway.add_param(*args, &block)
        end

        child.singleton_class.define_singleton_method(:inbound) do |*args, &block|
          name, opts = ParamsWrapper.get_name_and_opts(*args)
          _Railway.add_param(name, opts.merge(inbound: :true), &block)
        end

        child.singleton_class.define_singleton_method(:outbound) do |*keys|
          keys.each { |key| _Railway.add_param(key => nil, :type => :outbound) }
        end

        child.singleton_class.define_singleton_method(:validate) do |*args, &block|
          _Railway.add_validation(*args, &block)
        end

        child.singleton_class.define_singleton_method(:add_error) do |param, symbol, message, *args, &block|
          _Railway.add_error(param, symbol, message, *args, &block)
        end

        child.singleton_class.define_singleton_method(:step) do |*args, &block|
          _Railway.add_step({scope: :class}, *args, &block)
        end

        child.singleton_class.define_singleton_method(:failed) do |*args, &block|
          _Railway.add_failed({scope: :class}, *args, &block)
        end

        child.singleton_class.define_singleton_method(:async) do |*args, &block|
          _Railway.add_async({scope: :class}, *args, &block)
        end

        child.singleton_class.define_singleton_method(:_Railway) do
          Hyperloop::Context.set_var(self, :@_railway) do
            # overcomes a bug in Opal 0.9 which returns nil for singleton superclass
            my_super = superclass || `self.$$singleton_of`.superclass.singleton_class
            if my_super == Operation.singleton_class
              Class.new(Railway)
            else
              Class.new(my_super._Railway).tap do |wrapper|
                [:@validations, :@tracks, :@receivers].each do |var|
                  value = my_super._Railway.instance_variable_get(var)
                  wrapper.instance_variable_set(var, value && value.dup)
                end
              end
            end
          end
        end
      end
    end

    class Railway
      def initialize(operation)
        @operation = operation
      end
    end
  end
end
