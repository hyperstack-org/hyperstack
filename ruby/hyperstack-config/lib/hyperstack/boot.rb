# Define a primitive Boot Operation that will act like a full blown operation.
# If Operation is defined before this then we skip the whole exercise.  Likewise
# when Operation defines the Boot class, it will check for a receivers method and
# copy any defined receivers into the updated Boot class.

module Hyperstack
  unless defined? Operation
    class Operation
    end
    class Application
      class Boot < Operation
        class ReactDummyParams
          # behaves simplistically like a true Operation broadcast Params object with a
          # single param named context.
          attr_reader :context
          def initialize(context)
            @context = context
          end
        end
        class << self
          def on_dispatch(&block)
            receivers << block
          end

          def receivers
            # use the force: true option so that system code needing to receive
            # boot will NOT be erased on the next Hyperloop::Context.reset!
            Hyperstack::Context.set_var(self, :@receivers, force: true) { [] }
          end

          def run(context: nil)
            params = ReactDummyParams.new(context)
            receivers.each do |receiver|
              receiver.call params
            end
          end
        end
      end
    end
  end
end
