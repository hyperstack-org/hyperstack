if RUBY_ENGINE == 'opal'
  require 'hyperloop/client_stubs'
  require 'hyperloop/context'
  require 'hyperloop/on_client'
else
  require 'opal'
  require 'hyperloop/config_settings'
  require 'hyperloop/context'
  require 'hyperloop/imports'
  require 'hyperloop/client_readers'
  require 'hyperloop/on_client'
  require 'hyperloop/rail_tie' if defined? Rails
  Hyperloop.import 'opal', gem: true
  Hyperloop.import 'browser', client_only: true
  Hyperloop.import 'hyperloop-config', gem: true
  Hyperloop.import 'hyperloop/autoloader'
  Hyperloop.import 'hyperloop/autoloader_starter'

  Opal.append_path(File.expand_path('../', __FILE__).untaint)
end
