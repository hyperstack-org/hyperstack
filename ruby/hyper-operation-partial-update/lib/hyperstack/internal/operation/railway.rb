module Hyperstack
  module Internal
    module Operation
      class Railway
        def initialize(operation)
          @operation = operation
        end

        def receivers
          self.class.receivers
        end

        class << self
          def receivers
            # use the force: true option so that system code needing to receive
            # boot will NOT be erased on the next Hyperloop::Context.reset!
            Hyperloop::Context.set_var(self, :@receivers, force: true) { [] }
          end

          def add_receiver(&block)
            receivers << block
          end
        end

        def dispatch
          result.then do
            receivers.each do |receiver|
              receiver.call(
                self.class.params_wrapper.dispatch_params(@operation.params),
                @operation
              )
            end
          end
        end

        def process_params(args)
          self.class.params_wrapper.process_params(@operation, args)
        end

        def self.add_param(*args, &block)
          params_wrapper.add_param(*args, &block)
        end

        def self.params_wrapper
          Hyperloop::Context.set_var(self, :@params_wrapper) do
            if Railway == superclass
              Class.new(ParamsWrapper)
            else
              Class.new(superclass.params_wrapper).tap do |wrapper|
                hash_filter = superclass.params_wrapper.hash_filter
                wrapper.instance_variable_set('@hash_filter', hash_filter && hash_filter.dup)
                inbound_params = superclass.params_wrapper.inbound_params
                wrapper.instance_variable_set('@inbound_params', inbound_params && inbound_params.dup)
              end
            end
          end
        end

      end
    end
  end
end
