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
class MiniRacer::Context
  alias original_eval eval
  def eval(str, options=nil)
    original_eval str, options
  rescue Exception => e
    File.write('react_prerendering_src.js', str) rescue nil
    raise e
  end
end
