module Hyperloop
  class Operation

    class Exit < StandardError
      attr_reader :state
      attr_reader :result
      def initialize(state, result)
        @state = state
        @result = result
      end
    end

    class Railway

      def tracks
        self.class.tracks
      end

      class << self
        def tracks
          @tracks ||= []
        end

        def to_opts(tie, args, block)
          if args.count.zero?
            { run: block }
          elsif args[0].is_a?(Hash)
            {
              scope: args[0][:class] ? :class : args[0][:scope],
              run: args[0][:class] || args[0][:run] || block
            }
          elsif args[0] == :class && block
            { run: block, scope: :class }
          elsif args[0].is_a?(Class) && args[0] < Operation
            { run: proc { args[0].run(params) } }
          else
            scope = args[1][:scope] if args[1].is_a? Hash
            { run: args[0], scope: scope }
          end.merge(tie: instance_method(tie))
        end

        [:step, :failed, :async].each do |tie|
          define_method :"add_#{tie}" do |*args, &block|
            tracks << to_opts(tie, args, block)
          end
        end

        def abort!(arg)
          raise Exit.new(:failed, arg)
        end

        def succeed!(arg)
          raise Exit.new(:success, arg)
        end
      end

      def step(opts)
        if @last_result.is_a? Promise
          @last_result = @last_result.then do |*result|
            @last_result = result
            apply(opts, :in_promise)
          end
        elsif @state == :success
          apply(opts)
        end
      end

      def failed(opts)
        if @last_result.is_a? Promise
          @last_result = @last_result.fail do |e|
            @last_result = e
            apply(opts, :in_promise)
            raise @last_result if @last_result.is_a? Exception
            raise e
          end
        elsif @state == :failed
          apply(opts)
        end
      end

      def async(opts)
        apply(opts) if @state != :failed
      end

      def apply(opts, in_promise = nil)
        if opts[:scope] == :class
          args = [@operation, *@last_result]
          instance = @operation.class
        else
          args = @last_result
          instance = @operation
        end
        block = opts[:run]
        block = instance.method(block) if block.is_a? Symbol
        @last_result =
          if block.arity.zero?
            instance.instance_exec(&block)
          elsif args.is_a?(Array) && block.arity == args.count
            instance.instance_exec(*args, &block)
          else
            instance.instance_exec(args, &block)
          end
        return @last_result unless @last_result.is_a? Promise
        raise @last_result.error if @last_result.rejected?
        @last_result = @last_result.value if @last_result.resolved?
        @last_result
      rescue Exit => e
        @state = e.state
        @last_result = (e.state != :failed || e.result.is_a?(Exception)) ? e.result : e
        raise e
      rescue Exception => e
        @state = :failed
        @last_result = e
        raise e if in_promise
      end

      def run
        if @operation.has_errors? || @state
          @last_result ||= ValidationException.new(@operation.instance_variable_get('@errors'))
          return if @state  # handles abort out of validation
          @state = :failed
        else
          @state = :success
        end
        tracks.each { |opts| opts[:tie].bind(self).call(opts) }
      rescue Exit
      end

      def result
        return @last_result if @last_result.is_a? Promise
        @last_result =
          if @state == :success
            Promise.new.resolve(@last_result)
          else
            Promise.new.reject(@last_result)
          end
      end
    end
  end
end
