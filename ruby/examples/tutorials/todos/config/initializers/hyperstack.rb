# config/initializers/hyperloop.rb
# If you are not using ActionCable, see http://ruby-hyperloop.io/docs/models/configuring-transport/
Hyperstack.configuration do |config|
  config.transport = :action_cable # or :pusher or :simpler_poller or :none
  config.prerendering = :off # or :on
  #config.import 'reactrb/auto-import' # will automatically bridge js components to hyperloop components
  config.import 'jquery', client_only: true # remove this line if you don't need jquery
  config.import 'hyperstack/component/jquery', client_only: true # remove this line if you don't need jquery'
  #config.import 'react/ext/opal-jquery/element', client_only: true
  # config.import 'hyper-component/jquery', client_only: true
  config.import 'hyperstack/hotloader', client_only: true if Rails.env.development?
end
