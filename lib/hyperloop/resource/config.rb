if RUBY_ENGINE == 'opal'
  module Hyperloop
    def self.api_path
      Hyperloop::Resource::ClientDrivers.opts[:api_path]
    end

    def self.current_user_id
      Hyperloop::Resource::ClientDrivers.opts[:current_user_id]
    end
  end
else
  module Hyperloop

    # available settings
    class << self
      attr_accessor :action_cable_consumer_url
      attr_accessor :api_path
      attr_accessor :pusher
      attr_accessor :pusher_instance
      attr_accessor :redis_instance
      attr_accessor :resource_transport
      attr_accessor :valid_record_class_params
    end

    # default values
    self.pusher = {}
    self.resource_transport = :pusher
    self.valid_record_class_params = []

    def self.all_options
      options = {}
      options[:api_path] = api_path if api_path
      options[:action_cable_consumer_url] = action_cable_consumer_url if action_cable_consumer_url
      options[:pusher] = pusher if pusher && pusher != {}
      options[:resource_transport] = resource_transport if resource_transport
      options
    end
  end
end