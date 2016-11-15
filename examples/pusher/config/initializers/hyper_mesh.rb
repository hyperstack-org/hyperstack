# config/initializers/HyperMesh.rb
HyperMesh.configuration do |config|
  config.transport = :pusher
  config.channel_prefix = "HyperMesh"
  config.opts = {
    app_id: "2...9",
    key: "f...c",
    secret: "1....3"
  }
end
