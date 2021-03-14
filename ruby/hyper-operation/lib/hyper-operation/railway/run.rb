module Hyperstack
  class Operation

    class Exit < StandardError
      attr_reader :state
      attr_reader :result
      def initialize(state, result = nil)
        @state = state
        @result = result
      end
      def to_s
        @state
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

        def build_tie(tie, args, block)
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
            tracks << build_tie(tie, args, block)
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
        @promise_chain = @promise_chain
          .then { |result| apply(result, :success, opts) }
      end

      def failed(opts)
        @promise_chain = @promise_chain
          .always { |result| apply(result, :failed, opts) }
      end

      def async(opts)
        @promise_chain = @promise_chain_start = Promise.new
        @promise_chain.resolve(@last_async_result)
        step(opts)
      end

      def apply(result, state, opts)
        return result unless @state == state
        if opts[:scope] == :class
          args = [@operation, *result]
          instance = @operation.class
        else
          args = result
          instance = @operation
        end
        block = opts[:run]
        block = instance.method(block) if block.is_a? Symbol
        last_result =
          if block.arity.zero?
            instance.instance_exec(&block)
          elsif args.is_a?(Array) && block.arity == args.count
            instance.instance_exec(*args, &block)
          else
            instance.instance_exec(args, &block)
          end
        @last_async_result = last_result unless last_result.is_a? Promise
        last_result
      rescue Exit => e
        # the promise chain ends with an always block which will process
        # any immediate exits by checking the value of @state.   All other
        # step/failed/async blocks will be skipped because state will not equal
        # :succeed or :failed
        if e.state == :failed
          @state = :abort
          # exit via the final always block with the exception
          raise e.result.is_a?(Exception) ? e.result : e
        else
          @state = :succeed
          # exit via the final then block with the success value
          e.result
        end
      rescue Exception => e
        @state = :failed
        raise e
      end

      def run
        # if @operation.has_errors? || @state
        #   @last_result ||= ValidationException.new(@operation.instance_variable_get('@errors'))
        #   # following handles abort out of validation.  if state is already set then we are aborting
        #   # otherwise if state is not set but we have errors then we are failed
        #   @state ||= :failed
        # else
        #   @state = :success
        # end
        @state ||= :success
        @promise_chain_start = @promise_chain = Promise.new
        @promise_chain_start.resolve(@last_result)
        tracks.each { |opts| opts[:tie].bind(self).call(opts) } unless @state == :abort
      end

      def result
        @result ||= @promise_chain.always do |e|
          if %i[abort failed].include? @state
            if e.is_a? Exception
              raise e
            else
              raise Promise::Fail.new(e)
            end
          else
            e
          end
        end
      end
    end
  end
end
