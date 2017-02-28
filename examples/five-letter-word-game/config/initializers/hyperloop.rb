Hyperloop.configuration do |config|
  #config.transport = :simple_poller
  #config.opts = { seconds_between_poll: 5 }
  config.transport = :action_cable
end


    # # typically config/initializers/HyperMesh.rb
    # # or you can do a similar setup in your tests (see this gem's specs)
    # require 'pusher'
    # require 'pusher-fake'
    # # The app_id, key, and secret need to be assigned directly to Pusher
    # # so PusherFake will work.
    # Pusher.app_id = "MY_TEST_ID"      # you use the real or fake values
    # Pusher.key =    "MY_TEST_KEY"
    # Pusher.secret = "MY_TEST_SECRET"
    # # The next line actually starts the pusher-fake server (see the Pusher-Fake readme for details.)
    # require 'pusher-fake/support/base' # if using pusher with rspec change this to pusher-fake/support/rspec
    # # now copy over the credentials, and merge with PusherFake's config details
    # Hyperloop.configuration do |config|
    #   config.transport = :pusher
    #   config.channel_prefix = "HyperMesh"
    #   config.opts = {
    #     app_id: Pusher.app_id,
    #     key: Pusher.key,
    #     secret: Pusher.secret
    #   }.merge(PusherFake.configuration.web_options)
    # end

require 'hyper-react'
module ReactiveRuby
  class ComponentLoader
    def components
      'hyperloop'
    end
  end
end
