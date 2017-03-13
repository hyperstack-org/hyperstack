if RUBY_ENGINE == 'opal'
  require 'hyperloop/client_stubs'
  require 'hyperloop/on_client'
else
  require 'opal'
  require 'hyperloop/config_settings'
  require 'hyperloop/requires'
  require 'hyperloop/client_readers'
  require 'hyperloop/on_client'
  require 'hyperloop/rail_tie' if defined? Rails
  Hyperloop.require 'opal', gem: true
  Hyperloop.require 'hyperloop-config', gem: true
  Opal.append_path(File.expand_path('../', __FILE__).untaint)
end
