if RUBY_ENGINE == 'opal'
  require 'browser/delay'
  require 'hyper-store'
  require 'react'
  require 'react/observable'
  require 'hyperstack/props_wrapper'
  require 'hyperstack/validator'

  require 'react/component/dsl_instance_methods'
  require 'react/component/should_component_update'
  require 'react/component/tags'
  require 'react/component/base'
  require 'react/element'
  require 'react/event'
  require 'react/api'
  require 'react/rendering_context'
  require 'react/state'
  require 'react/object'
  require 'react/to_key'
  require 'reactive-ruby/isomorphic_helpers'
  require 'hyperstack/params/class_methods'
  require 'hyperstack/params/instance_methods'
  require 'hyperstack/component/mixin'
  require 'hyperstack/component'
  require 'hyperstack/context'
  require 'hyperstack/top_level'
else
  require 'oj'
  require 'opal'
  require 'hyper-store'
  require 'opal-activesupport'
  require 'opal-browser'
  require 'hyperstack/component/version'
  require 'reactive-ruby/isomorphic_helpers' # obsolete, but still needed in router
  require 'reactive-ruby/serializers' # same
  require 'hyperstack/promise'
  require 'hyperstack/config'
  require 'hyperstack/view_helpers'
  Opal.append_path(__dir__.untaint)
  if defined?(Rails)
    module Hyperstack
      module Model
        class Railtie < Rails::Railtie
          def delete_first(a, e)
            a.delete_at(a.index(e) || a.length)
          end

          config.before_configuration do |_|
            Rails.configuration.tap do |config|
              # rails will add everything immediately below app to eager and auto load, so we need to remove it
              delete_first config.eager_load_paths, "#{config.root}/app/hyperstack"

              unless Rails.env.production?
                # rails will add everything immediately below app to eager and auto load, so we need to remove it
                delete_first config.autoload_paths, "#{config.root}/app/hyperstack"
              end
            end
          end
        end
      end
    end
  end
  if Dir.exist?(File.join('app', 'hyperstack'))
    # Opal.append_path(File.expand_path(File.join('app', 'hyperstack', 'components')))
    Opal.append_path(File.expand_path(File.join('app', 'hyperstack'))) unless Opal.paths.include?(File.expand_path(File.join('app', 'hyperstack')))
  elsif Dir.exist?('hyperstack')
    # Opal.append_path(File.expand_path(File.join('hyperstack', 'components')))
    Opal.append_path(File.expand_path('hyperstack')) unless Opal.paths.include?(File.expand_path('hyperstack'))
  end
end
