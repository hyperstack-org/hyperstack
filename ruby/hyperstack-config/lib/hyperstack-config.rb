require 'hyperstack/boot'
module Hyperstack
  def self.naming_convention
    :camelize_params
  end
end
if RUBY_ENGINE == 'opal'
  require 'hyperstack/native_wrapper_compatibility' # needs to be early...
  require 'hyperstack/deprecation_warning'
  require 'hyperstack/string'
  require 'hyperstack/client_stubs'
  require 'hyperstack/context'
  require 'hyperstack/js_imports'
  require 'hyperstack/on_client'
  require 'hyperstack/active_support_string_inquirer.rb'
  require 'hyperstack_env'
  require 'hyperstack/hotloader/stub'
else
  require 'opal'
  require 'opal-browser'
  # We need opal-rails to be loaded for Gem code to be properly included by sprockets.
  begin
    require 'opal-rails' if defined? Rails
  rescue LoadError
    puts "****** WARNING: To use Hyperstack with Rails you must include the 'opal-rails' gem in your gem file."
  end
  require 'hyperstack/config_settings'
  require 'hyperstack/context'
  require 'hyperstack/imports'
  require 'hyperstack/js_imports'
  require 'hyperstack/client_readers'
  require 'hyperstack/on_client'

  if defined? Rails
    require 'hyperstack/rail_tie'
  end
  require 'hyperstack/active_support_string_inquirer.rb' unless defined? ActiveSupport
  require 'hyperstack/env'
  require 'hyperstack/on_error'
  Hyperstack.define_setting :hotloader_port, 25222
  Hyperstack.define_setting :hotloader_ping, nil
  Hyperstack.define_setting :hotloader_ignore_callback_mapping, false
  Hyperstack.import 'opal', gem: true
  Hyperstack.import 'native', client_only: true
  Hyperstack.import 'promise', client_only: true
  Hyperstack.import 'browser/setup/full', client_only: true
  Hyperstack.import 'hyperstack-config', gem: true
  Hyperstack.import 'hyperstack/autoloader'
  Hyperstack.import 'hyperstack/autoloader_starter'
  # based on the environment pick the directory containing the file with the matching
  # value for the client.  This avoids use of ERB for builds outside of sprockets environment
  Opal.append_path(File.expand_path("../hyperstack/environment/#{Hyperstack.env}/", __FILE__).untaint)
  Opal.append_path(File.expand_path('../', __FILE__).untaint)
end
