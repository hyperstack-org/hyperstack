Hyperstack.configuration do |config|
  config.prerendering = :off
  config.import 'jquery', client_only: true
  config.import 'hyperstack/component/jquery', client_only: true
  config.import 'browser/interval'
  config.import 'active_support'
  config.import 'hyperstack/hotloader', client_only: true if Rails.env.development?
  config.hotloader_port = 25223
end
