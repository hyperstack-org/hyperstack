require 'opal-activesupport'
require 'hyperstack/resource/version'
require 'hyper-store'
require 'hyper-react'
require 'hyper-transport'

if RUBY_ENGINE == 'opal'
  require 'hyper-transport-http' # TODO, this is actually optional, might a different transport
  require 'hyper_record'
else
  require 'oj'
  require 'hyperstack/resource/config'
  require 'hyperstack/resource/security_guards' # server side, controller helper methods
  require 'hyper_record'
  Opal.append_path(__dir__.untaint)
  if Dir.exist?(File.join('app', 'hyperstack', 'models'))
    # Opal.append_path(File.expand_path(File.join('app', 'hyperstack', 'models')))  <- opal-autoloader will handle this
    Opal.append_path(File.expand_path(File.join('app', 'hyperstack', 'models', 'concerns')))
    Opal.append_path(File.expand_path(File.join('app', 'hyperstack'))) unless Opal.paths.include?(File.expand_path(File.join('app', 'hyperstack')))
  elsif Dir.exist?(File.join('hyperstack', 'models'))
    # Opal.append_path(File.expand_path(File.join('hyperstack', 'models')))  <- opal-autoloader will handle this
    Opal.append_path(File.expand_path(File.join('hyperstack', 'models', 'concerns')))
    Opal.append_path(File.expand_path(File.join('hyperstack'))) unless Opal.paths.include?(File.expand_path(File.join('hyperstack')))
  end

  # special treatment for rails
  if defined?(Rails)
    module Hyperstack
      module Resource
        class Railtie < Rails::Railtie
          def delete_first(a, e)
            a.delete_at(a.index(e) || a.length)
          end

          config.before_configuration do |_|
            Rails.configuration.tap do |config|
              config.eager_load_paths += %W(#{config.root}/app/hyperstack/handlers)
              config.eager_load_paths += %W(#{config.root}/app/hyperstack/models)
              config.eager_load_paths += %W(#{config.root}/app/hyperstack/models/concerns)
              # rails will add everything immediately below app to eager and auto load, so we need to remove it
              delete_first config.eager_load_paths, "#{config.root}/app/hyperstack"

              unless Rails.env.production?
                config.autoload_paths += %W(#{config.root}/app/hyperstack/handlers)
                config.autoload_paths += %W(#{config.root}/app/hyperstack/models)
                config.autoload_paths += %W(#{config.root}/app/hyperstack/models/concerns)
                # rails will add everything immediately below app to eager and auto load, so we need to remove it
                delete_first config.autoload_paths, "#{config.root}/app/hyperstack"
              end
            end
          end
        end
      end
    end
  elsif Dir.exist?(File.join('app', 'hyperstack'))
    $LOAD_PATH.unshift(File.expand_path(File.join('app', 'hyperstack', 'handlers')))
    $LOAD_PATH.unshift(File.expand_path(File.join('app', 'hyperstack', 'models')))
    $LOAD_PATH.unshift(File.expand_path(File.join('app', 'hyperstack', 'models', 'concerns')))
  elsif Dir.exist?(File.join('hyperstack'))
    $LOAD_PATH.unshift(File.expand_path(File.join('hyperstack', 'handlers')))
    $LOAD_PATH.unshift(File.expand_path(File.join('hyperstack', 'models')))
    $LOAD_PATH.unshift(File.expand_path(File.join('hyperstack', 'models', 'concerns')))
  end
end
