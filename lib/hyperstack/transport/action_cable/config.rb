if RUBY_ENGINE != 'opal'
  module Hyperstack

    # available settings
    class << self
      attr_accessor :action_cable_consumer_url
    end

    self.add_client_options(%i[action_cable_consumer_url])
    self.add_client_init_class_name('Hyperstack::Transport::ActionCable::ClientDriver')

    # default values
    self.action_cable_consumer_url = ""
    self.server_pub_sub_driver = Hyperstack::Transport::ActionCable::ServerDriver
  end
end