if RUBY_ENGINE != 'opal'
  module Hyperstack

    # available settings
    class << self
      attr_accessor :pusher_options
      attr_accessor :pusher_server_options
    end

    self.add_client_option(:pusher_options)
    self.add_client_init_class_name('Hyperstack::Transport::Pusher::ClientDriver')

    # default values
    self.pusher_options = {}
    self.pusher_server_options = {}
    self.server_pub_sub_driver = Hyperstack::Transport::Pusher::ServerDriver
  end
end