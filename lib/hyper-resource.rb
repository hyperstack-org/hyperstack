require 'opal-activesupport'
require 'hyperloop/resource/version'
require 'hyperloop/resource/config'
require 'hyper-store'

if RUBY_ENGINE == 'opal'
  require 'hyper-transport-http'
  require 'hyperloop/resource/client_drivers' # initialize options for the client
  require 'hyperloop/resource/notification_processor'
  require 'hyperloop/resource/response_processor'
  require 'hyper_record'
else
  require 'hyperloop/resource/pub_sub' # server side, controller helper methods
  require 'hyperloop/resource/security_guards' # server side, controller helper methods
  require 'hyperloop/resource/view_helpers'
  require 'hyperloop/resource/handler'
  require 'hyper_record'
  Opal.append_path(__dir__.untaint)
  if Dir.exist?(File.join('app', 'hyperloop', 'models'))
    # Opal.append_path(File.expand_path(File.join('app', 'hyperloop', 'models')))
    Opal.append_path(File.expand_path(File.join('app', 'hyperloop', 'models', 'concerns')))
    Opal.append_path(File.expand_path(File.join('app', 'hyperloop', 'operations')))
    Opal.append_path(File.expand_path(File.join('app', 'hyperloop'))) unless Opal.paths.include?(File.expand_path(File.join('app', 'hyperloop')))
  elsif Dir.exist?(File.join('hyperloop', 'models'))
    # Opal.append_path(File.expand_path(File.join('hyperloop', 'models')))
    Opal.append_path(File.expand_path(File.join('hyperloop', 'models', 'concerns')))
    Opal.append_path(File.expand_path(File.join('hyperloop', 'operations')))
    Opal.append_path(File.expand_path(File.join('hyperloop'))) unless Opal.paths.include?(File.expand_path(File.join('hyperloop')))
  end

  # special treatment for rails
  if defined?(Rails)
    module Hyperloop
      module Resource
        class Railtie < Rails::Railtie
          def delete_first(a, e)
            a.delete_at(a.index(e) || a.length)
          end

          config.before_configuration do |_|
            Rails.configuration.tap do |config|
              config.eager_load_paths += %W(#{config.root}/app/hyperloop/handlers)
              config.eager_load_paths += %W(#{config.root}/app/hyperloop/models)
              config.eager_load_paths += %W(#{config.root}/app/hyperloop/models/concerns)
              config.eager_load_paths += %W(#{config.root}/app/hyperloop/operations)
              # rails will add everything immediately below app to eager and auto load, so we need to remove it
              delete_first config.eager_load_paths, "#{config.root}/app/hyperloop"

              unless Rails.env.production?
                config.autoload_paths += %W(#{config.root}/app/hyperloop/handlers)
                config.autoload_paths += %W(#{config.root}/app/hyperloop/models)
                config.autoload_paths += %W(#{config.root}/app/hyperloop/models/concerns)
                config.autoload_paths += %W(#{config.root}/app/hyperloop/operations)
                # rails will add everything immediately below app to eager and auto load, so we need to remove it
                delete_first config.autoload_paths, "#{config.root}/app/hyperloop"
              end
            end
          end
        end
      end
    end
  elsif Dir.exist?(File.join('app', 'hyperloop'))
    $LOAD_PATH.unshift(File.expand_path(File.join('app', 'hyperloop', 'handlers')))
    $LOAD_PATH.unshift(File.expand_path(File.join('app', 'hyperloop', 'models')))
    $LOAD_PATH.unshift(File.expand_path(File.join('app', 'hyperloop', 'models', 'concerns')))
    $LOAD_PATH.unshift(File.expand_path(File.join('app', 'hyperloop', 'operations')))
  elsif Dir.exist?(File.join('hyperloop'))
    $LOAD_PATH.unshift(File.expand_path(File.join('hyperloop', 'handlers')))
    $LOAD_PATH.unshift(File.expand_path(File.join('hyperloop', 'models')))
    $LOAD_PATH.unshift(File.expand_path(File.join('hyperloop', 'models', 'concerns')))
    $LOAD_PATH.unshift(File.expand_path(File.join('hyperloop', 'operations')))
  end
end
