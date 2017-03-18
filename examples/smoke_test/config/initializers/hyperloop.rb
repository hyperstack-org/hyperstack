# require 'pusher'
# require 'pusher-fake'
# Pusher.app_id = "MY_TEST_ID"
# Pusher.key =    "MY_TEST_KEY"
# Pusher.secret = "MY_TEST_SECRET"
# require "pusher-fake/support/base"
#
# Hyperloop.configuration do |config|
#   config.import 'browser/interval', client_only: true, gem: true
#   #config.transport = :action_cable
#   # then setup your config like pusher but merge in the pusher fake
#   # options
#   config.transport = :pusher
#   config.opts = {
#     app_id: Pusher.app_id,
#     key: Pusher.key,
#     secret: Pusher.secret
#   }.merge(PusherFake.configuration.web_options)
# end

Hyperloop.configuration do |config|
  config.import 'browser/interval', client_only: true, gem: true
  config.transport = :action_cable
  # # then setup your config like pusher but merge in the pusher fake
  # # options
  # config.transport = :pusher
  # config.opts = {
  #   app_id: "231629",
  #   key: "f1b311cfea93678071dc",
  #   secret: "179de0c4a47c2b0503d3"
  # }
end
