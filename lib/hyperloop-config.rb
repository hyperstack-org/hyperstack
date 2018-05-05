if RUBY_ENGINE == 'opal'
  require 'hyperloop/string'
  require 'hyperloop/client_stubs'
  require 'hyperloop/context'
  require 'hyperloop/on_client'
  require 'hyperloop/active_support_string_inquirer.rb'
  require 'hyperloop_env'
else
  require 'opal'
  require 'opal-browser'
  require 'opal-rails' if defined? Rails
  require 'hyperloop/config_settings'
  require 'hyperloop/context'
  require 'hyperloop/imports'
  require 'hyperloop/client_readers'
  require 'hyperloop/on_client'
  require 'hyperloop/rail_tie' if defined? Rails
  require 'hyperloop/active_support_string_inquirer.rb' unless defined? ActiveSupport
  require 'hyperloop/env'
  Hyperloop.import 'opal', gem: true
  Hyperloop.import 'browser', client_only: true
  Hyperloop.import 'hyperloop-config', gem: true
  Hyperloop.import 'hyperloop/autoloader'
  Hyperloop.import 'hyperloop/autoloader_starter'
  # based on the environment pick the directory containing the file with the matching
  # value for the client.  This avoids use of ERB for builds outside of sprockets environment
  Opal.append_path(File.expand_path("../hyperloop/environment/#{Hyperloop.env}/", __FILE__).untaint)
  Opal.append_path(File.expand_path('../', __FILE__).untaint)
end
