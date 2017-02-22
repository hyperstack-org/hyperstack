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

      class << self
        def add_param(*args, &block)
          Hyperloop::Operation::ParamsWrapper.add_param(hash_filter, *args, &block)
        end

        def add_validation(*args, &block)
          validations << [args, block]
        end

        def add_error(param, symbol, message, *args, &block)
          add_validation do
            add_error(param, symbol, message) if call_block_with_context(args, block)
          end
        end

        def add_step(*args, &block)
          railway << [:step, args, block]
        end

        def add_failed(*args, &block)
          railway << [:failed, args, block]
        end

        def add_async(*args, &block)
          railway << [:async, args, block]
        end

        def apply(op, state, result, args, block)
          if block.arity == 0
            [state, op.instance_eval &block]
          elsif result.is_a? Array && block.arity == result.count
            [state, op.instance_exec(*result, &block)]
          else
            [state, op.instance_exec(result, block)]
          end
        rescue Exception => e
          [:failed, e]
        end

        def run(op)
          state = :success # or :failed if @errors
          result = nil
          railway.each do |tie|
            case tie[0]
            when :step
              if result.is_a? Promise
                result = result.then { |*result| apply(op, :success, result, *tie[1..2]) }
              elsif state == :success
                state, result = apply(op, state, result, tie[1], tie[2])
              end
            when :failed
              if result.is_a? Promise
                result = result.fail { |*result| apply(op, :failed, result, *tie[1..2]) }
              elsif state == :failed
                state, result = apply(op, state, result, tie[1], tie[2])
              end
            when :async
              state, result = apply(op, state, result, tie[1], tie[2]) if state != :failed
            end
          end
        rescue Hyperloop::Operation::Wrapper::Exit => e
          result, state = [e.result, e.state]
        ensure
          if result.is_a? Promise
            result
          elsif state == :failed
            Promise.new.reject(result)
          else
            Promise.new.resolve(result)
          end
        end




# THIS SHOULD BE ADDED ONLY IN ServerOps
        def dispatch_to(*args, &block)
          dispatches << [args, block]
        end

        def hash_filter
          @hash_filter ||= Mutations::HashFilter.new
        end

        def validations
          @validations ||= []
        end



        def dispatches
          @dispatches ||= []
        end
