#config/initializers/synchromesh.rb
HyperMesh.configuration do |config|
  config.transport = :action_cable
  config.channel_prefix = "synchromesh"
end
