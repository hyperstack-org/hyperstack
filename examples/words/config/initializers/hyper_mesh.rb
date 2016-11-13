#config/initializers/hyper_mesh.rb

#puts "*****  #{__FILE__} ****"
#binding.pry
#File.join(Rails.root, 'app', 'models', 'public')
#binding.pry
#Opal.append_path File.join(Rails.root, 'app', 'models').untaint



HyperMesh.configuration do |config|
  config.transport = :action_cable
  config.channel_prefix = "synchromesh"
end
