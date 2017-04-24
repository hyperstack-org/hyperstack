Hyperloop.configuration do |config|
  config.transport = :action_cable
  config.import 'opal_hot_reloader'
end
# require 'pusher'
# require 'pusher-fake'
# Pusher.app_id = "MY_TEST_ID"
# Pusher.key =    "MY_TEST_KEY"
# Pusher.secret = "MY_TEST_SECRET"
# require "pusher-fake/support/base"
#
# Hyperloop.configuration do |config|
#   config.transport = :pusher
#   config.opts = {
#     app_id: Pusher.app_id,
#     key: Pusher.key,
#     secret: Pusher.secret
#   }.merge(PusherFake.configuration.web_options)
# end
