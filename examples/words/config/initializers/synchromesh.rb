#config/initializers/synchromesh.rb
Synchromesh.configuration do |config|
  config.transport = :action_cable
  config.channel_prefix = "synchromesh"
end
