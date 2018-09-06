module Hyperstack
  # available settings
  class << self
    attr_accessor :api_path
    attr_accessor :authorization_driver
    attr_accessor :client_transport_driver_class_name
    attr_accessor :transport_notification_channel_prefix

    attr_accessor :server_pub_sub_driver
  end

  self.add_client_options(%i[api_path client_transport_driver_class_name transport_notification_channel_prefix])
  self.add_client_init_class_name('Hyperstack::Transport::ClientDrivers')

  # defaults
  self.api_path = '/hyperstack/api/endpoint'
  self.client_transport_driver_class_name = 'Hyperstack::Transport::HTTP'
  self.authorization_driver = nil
  self.transport_notification_channel_prefix = 'hyper-transport-notifications-'
end
