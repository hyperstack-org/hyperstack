if RUBY_ENGINE != 'opal'
  module Hyperloop

    # available settings
    class << self
      attr_accessor :api_path
      attr_accessor :redis_instance
      attr_accessor :notification_transport
      attr_accessor :resource_transport
      attr_accessor :valid_record_class_params
    end

    self.add_client_options(%i[api_path notification_transport resource_transport])

    # default values
    self.resource_transport = 'Hyperloop::Transport::HTTP'
    self.notification_transport = :pusher
    self.valid_record_class_params = []
  end
end