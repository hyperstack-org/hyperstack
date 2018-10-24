Hyperstack.configuration do |config|
  config.prerendering = :on
  config.import 'hyperstack/hotloader', client_only: true if Rails.env.development?
  config.hotloader_port = 25223
end
