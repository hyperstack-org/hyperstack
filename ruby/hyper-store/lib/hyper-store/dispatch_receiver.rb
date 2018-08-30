module HyperStore
  module DispatchReceiver
    class InvalidOperationError < StandardError; end

    attr_accessor :params

    def receives(*args, &block)
      # Format the callback to be Proc or Nil
      callback = format_callback(args)

      if args.empty?
        message = 'At least one operation must be passed in to the \'receives\' macro'
        raise InvalidOperationError, message
      end

      # Loop through receivers and call callback and block on dispatch
      args.each do |operation|
        operation.on_dispatch do |params|
          @params = params

          callback.call if callback
          yield params if block
        end
      end
    end

    private

    def format_callback(args)
      if args.last.is_a?(Symbol)
        method_name = args.pop
        -> { send(:"#{method_name}") }
      elsif args.last.is_a?(Proc)
        args.pop
      end
    end
  end
end
