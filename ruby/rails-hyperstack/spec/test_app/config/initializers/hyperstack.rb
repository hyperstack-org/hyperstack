# config/initializers/hyperstack.rb
# If you are not using ActionCable, see http://hyperstack.orgs/docs/models/configuring-transport/
Hyperstack.configuration do |config|
  config.transport = :action_cable # or :pusher or :simpler_poller or :none
  config.prerendering = :off # or :on
  config.import 'jquery', client_only: true  # remove this line if you don't need jquery
  config.import 'hyperstack/component/jquery', client_only: true # remove this line if you don't need jquery
  config.import 'hyperstack/hotloader', client_only: true if Rails.env.development?
end
