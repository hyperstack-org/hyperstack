# require 'pusher'
# Pusher.app_id = "MY_TEST_ID"
# Pusher.key = "MY_TEST_KEY"
# Pusher.secret = "MY_TEST_SECRET"
# require 'pusher-fake'
#
# HyperMesh.configuration do |config|
#   config.transport = :pusher
#   config.channel_prefix = "synchromesh"
#   config.opts = {app_id: Pusher.app_id, key: Pusher.key, secret: Pusher.secret}.merge(PusherFake.configuration.web_options)
# end
