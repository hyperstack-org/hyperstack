Hyperloop.configuration do |config|
  # helper = Webpacker::Helper
  # config.transport = :action_cable
  config.import 'reactrb/auto-import'
  config.import 'opal_hot_reloader'
  config.cancel_import 'react/react-source-browser' # bring your own React and ReactRouter via Yarn/Webpacker
  #config.console_auto_start = false
  # config.import File.basename(Webpacker.manifest.lookup!('application.js'))
end
