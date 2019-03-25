module Hyperstack
  module Internal
    module Receiver
      class << self
        def mount(receiver, *args, &block)
          return if receiver.respond_to?(:unmounted?) && receiver.unmounted?
          # Format the callback to be Proc or Nil
          callback = format_callback(receiver, args)

          # Loop through receivers and call callback and/or block on dispatch
          args.each do |operation|
            id = operation.on_dispatch do |params|
              callback.call(params) if callback
              yield params if block
            end
            # TODO: broadcaster classes need to define unmount as well
            AutoUnmount.objects_to_unmount[receiver] << id if receiver.respond_to? :unmount
          end
        end

        def format_callback(receiver, args)
          call_back =
            if args.last.is_a?(Symbol)
              method_name = args.pop
              ->(*aargs) { receiver.send(:"#{method_name}", *aargs) }
            elsif args.last.is_a?(Proc)
              args.pop
            end
          return call_back unless args.empty?
          message = 'At least one operation must be passed in to the \'receives\' macro'
          raise Legacy::Store::InvalidOperationError, message
        end
      end
    end
  end
end
