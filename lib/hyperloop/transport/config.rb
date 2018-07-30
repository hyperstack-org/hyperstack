if RUBY_ENGINE != 'opal'
  module Hyperloop

    # available settings
    class << self
      attr_accessor :action_cable_consumer_url
      attr_accessor :pusher
      attr_accessor :pusher_instance
    end

    self.add_client_options(%i[action_cable_consumer_url pusher])

    # default values
    self.pusher = {}
  end
end