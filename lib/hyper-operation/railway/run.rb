module Hyperloop
  class Operation
    class Railway

      class Exit < StandardError
        attr_reader :state
        attr_reader :result
        def initialize(state, result)
          @state = state
          @result = result
        end
      end

      def tracks
        self.class.tracks
      end

      class << self
        def tracks
          @tracks ||= []
        end

        def to_opts(args)
          args.first || {}
        end

        [:step, :failed, :async].each do |meth|
          define_method :"add_#{meth}" do |*args, block|
            tracks << [instance_method(meth), to_opts(args), block]
          end
        end

        def abort!(args)
          raise Exit.new(:failed, args)
        end

        def succeed!(args)
          raise Exit.new(:success, args)
        end
      end

      def step(opts, block)
        if @last_result.is_a? Promise
          @last_result = @last_result.then do |*result|
            @last_result = result
            apply(:success, opts, block)
          end
        elsif @state == :success
          apply(:success, opts, block)
        end
      end

      def failed(opts, block)
        if @last_result.is_a? Promise
          @last_result = @last_result.fail do |*result|
            @last_result = result
            apply(:failed, opts, block)
          end
        elsif @state == :failed
          apply(:failed, opts, block)
        end
      end

      def async(opts, block)
        apply(:failed, opts, block) if @state != :failed
      end

      def apply(state, opts, block)
        @last_result =
          if block.arity.zero?
            @operation.instance_eval(&block)
          elsif @last_result.is_a?(Array) && block.arity == result.count
            @operation.instance_exec(*@last_result, &block)
          else
            @operation.instance_exec(@last_result, block)
          end
      rescue Exit => e
        @state = e.state
        @last_result = e.result
        raise e
      rescue Exception => e
        @state = :failed
        @last_result = e
      end

      def run
        return if @state
        if @operation.has_errors?
          @state = :failed
          @last_result = ValidationException.new(@operation.instance_variable_get('@errors'))
        else
          @state = :success
        end
        tracks.each { |tie, opts, block| tie.bind(self).call(opts, block) }
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
