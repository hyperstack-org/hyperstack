# don't put this in directory lib/rspec/ as that will cause stack overflow with rails/rspec loads
module RSpec
  module Expectations
    class ExpectationTarget; end
    module HyperSpecInstanceMethods
      def self.included(base)
        base.include HyperSpec::ComponentTestHelpers
      end

      def to_on_client(matcher, message = nil, &block)
        evaluate_client.to(matcher, message, &block)
      end

      alias on_client_to to_on_client
      alias to_then to_on_client
      alias then_to to_on_client

      def to_on_client_not(matcher, message = nil, &block)
        evaluate_client.not_to(matcher, message, &block)
      end

      alias on_client_to_not to_on_client_not
      alias on_client_not_to to_on_client_not
      alias to_not_on_client to_on_client_not
      alias not_to_on_client to_on_client_not
      alias then_to_not to_on_client_not
      alias then_not_to to_on_client_not
      alias to_not_then to_on_client_not
      alias not_to_then to_on_client_not

      private

      def evaluate_client
        source = add_opal_block(@args_str, @target)
        value = @target.binding.eval("evaluate_ruby(#{source.inspect}, {}, {})")
        ExpectationTarget.for(value, nil)
      end
    end

    class OnClientWithArgsTarget
      include HyperSpecInstanceMethods

      def initialize(target, args)
        unless args.is_a? Hash
          raise ExpectationNotMetError,
                "You must pass a hash of local var, value pairs to the 'with' modifier"
        end

        @target = target
        @args_str = args.collect do |name, value|
          set_local_var(name, value)
        end.join("\n")
      end
    end

    class BlockExpectationTarget < ExpectationTarget
      include HyperSpecInstanceMethods

      def with(args)
        OnClientWithArgsTarget.new(@target, args)
      end
    end
  end
end
