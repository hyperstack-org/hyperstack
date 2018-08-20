require 'opal'
require 'hyperloop/business/version'
require 'hyper-store'
require 'hyper-react'
require 'hyper-transport'

if RUBY_ENGINE == 'opal'
  require 'promise'
  require 'native'
  require 'hyperloop/props_wrapper'
  require 'hyperloop/params/instance_methods'
  require 'hyperloop/params/class_methods'
  require 'hyperloop/validator'
  require 'hyperloop/business/class_methods'
  require 'hyperloop/business/mixin'
  require 'hyperloop/business'
else
  require 'hyperloop/business/promise'
  require 'hyperloop/props_wrapper'
  require 'hyperloop/params/instance_methods'
  require 'hyperloop/params/class_methods'
  require 'hyperloop/validator'
  require 'hyperloop/business/class_methods'
  require 'hyperloop/business/mixin'
  require 'hyperloop/business'
  Opal.append_path(__dir__.untaint) unless Opal.paths.include?(__dir__.untaint)
  if Dir.exist?(File.join('app', 'hyperloop', 'operations'))
    # Opal.append_path(File.expand_path(File.join('app', 'hyperloop', 'operations'))) <- opal-autoloader will handle this
    Opal.append_path(File.expand_path(File.join('app', 'hyperloop'))) unless Opal.paths.include?(File.expand_path(File.join('app', 'hyperloop')))
  elsif Dir.exist?(File.join('hyperloop', 'operations'))
    # Opal.append_path(File.expand_path(File.join('hyperloop', 'models', 'operations'))) <- opal-autoloader will handle this
    Opal.append_path(File.expand_path(File.join('hyperloop'))) unless Opal.paths.include?(File.expand_path(File.join('hyperloop')))
  end

  # special treatment for rails
  if defined?(Rails)
    module Hyperstack
      class Business
        class Railtie < Rails::Railtie
          def delete_first(a, e)
            a.delete_at(a.index(e) || a.length)
          end

          config.before_configuration do |_|
            Rails.configuration.tap do |config|
              config.eager_load_paths += %W(#{config.root}/app/hyperloop/handlers)
              config.eager_load_paths += %W(#{config.root}/app/hyperloop/operations)
              # rails will add everything immediately below app to eager and auto load, so we need to remove it
              delete_first config.eager_load_paths, "#{config.root}/app/hyperloop"

              unless Rails.env.production?
                config.autoload_paths += %W(#{config.root}/app/hyperloop/handlers)
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
    # TODO unless
    $LOAD_PATH.unshift(File.expand_path(File.join('app', 'hyperloop', 'handlers')))
    $LOAD_PATH.unshift(File.expand_path(File.join('app', 'hyperloop', 'operations')))
  elsif Dir.exist?(File.join('hyperloop'))
    $LOAD_PATH.unshift(File.expand_path(File.join('hyperloop', 'handlers')))
    $LOAD_PATH.unshift(File.expand_path(File.join('hyperloop', 'operations')))
  end
end
