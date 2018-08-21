module Hyperstack
  module Transport
    class ClientDrivers
      # @private
      def self.init
        return if @initialized
        if Hyperstack.options.has_key?(:client_transport_driver_class_name)
          Hyperstack.define_singleton_method(:client_transport_driver) do
            @client_transport_driver
          end
          Hyperstack.define_singleton_method(:client_transport_driver=) do |driver|
            @client_transport_driver = driver
          end
          Hyperstack.client_transport_driver = Hyperstack.client_transport_driver_class_name.constantize
        end
        @initialized = true
      end
    end
  end
end
