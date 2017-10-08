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
  Hyperloop::Autoloader.load_paths = %w[components models operations stores]

  class Object
    class << self
      alias _autoloader_original_const_missing const_missing

      def const_missing(const_name)
        # need to call original code because some things are set up there
        # original code may also be overloaded by reactrb, for example
        _autoloader_original_const_missing(const_name)
      rescue StandardError => e
        Hyperloop::Autoloader.const_missing(const_name, self) || raise(e)
      end
    end
  end

  Opal.append_path(File.expand_path('../', __FILE__).untaint)
end
