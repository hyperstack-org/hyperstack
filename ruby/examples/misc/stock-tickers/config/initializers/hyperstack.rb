Hyperstack.configuration do |config|
  config.prerendering = :on
  config.import 'hyperstack-jquery'
  config.import 'browser/interval'
  config.import 'active_support'
  config.import 'hyperstack/hotloader', client_only: true if Rails.env.development?
  config.hotloader_port = 25223
end
