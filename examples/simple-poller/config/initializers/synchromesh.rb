
HyperMesh.configuration do |config|
  config.transport = :simple_poller
  #config.opts[:noisy] = true
end

# HyperMesh.configuration do |config|
#   config.transport = :pusher
#   config.channel_prefix = "synchromesh"
#   config.opts = {
#     app_id: '231629',
#     key:    'f1b311cfea93678071dc',
#     secret: '179de0c4a47c2b0503d3'
#   }
# end
