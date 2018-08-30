require 'opal-activesupport'
require 'hyper-transport'

if RUBY_ENGINE == 'opal'
  require 'hyperstack_policy_processor'
  # nothing else
else
  require 'active_support'
  require 'oj'
  require 'hyperstack/promise'
  require 'hyperstack/policy/class_methods'
  require 'hyperstack/policy/instance_methods'
  require 'hyperstack/policy/policy_definition'
  require 'hyperstack/policy'

  Opal.append_path(__dir__.untaint) unless Opal.paths.include?(__dir__.untaint)

  if Dir.exist?(File.join('app', 'hyperstack', 'policies'))
    Opal.append_path(File.expand_path(File.join('app', 'hyperstack', 'policies')))
    Opal.append_path(File.expand_path(File.join('app', 'hyperstack'))) unless Opal.paths.include?(File.expand_path(File.join('app', 'hyperstack')))
  elsif Dir.exist?(File.join('hyperstack', 'models'))
    Opal.append_path(File.expand_path(File.join('hyperstack', 'policies')))
    Opal.append_path(File.expand_path(File.join('hyperstack'))) unless Opal.paths.include?(File.expand_path(File.join('hyperstack')))
  end

  if defined?(Rails)
    module Hyperstack
      module Policy
        class Railtie < Rails::Railtie
          def delete_first(a, e)
            a.delete_at(a.index(e) || a.length)
          end

          config.before_configuration do |_|
            Rails.configuration.tap do |config|
              config.eager_load_paths += %W(#{config.root}/app/hyperstack/policies)
              delete_first config.eager_load_paths, "#{config.root}/app/hyperstack"

              unless Rails.env.production?
                config.autoload_paths += %W(#{config.root}/app/hyperstack/policies)
                # rails will add everything immediately below app to eager and auto load, so we need to remove it
                delete_first config.autoload_paths, "#{config.root}/app/hyperstack"
              end
            end
          end
        end
      end
    end
  elsif Dir.exist?(File.join('app', 'hyperstack'))
    # TODO unless
    $LOAD_PATH.unshift(File.expand_path(File.join('app', 'hyperstack', 'policies')))
  elsif Dir.exist?(File.join('hyperstack'))
    $LOAD_PATH.unshift(File.expand_path(File.join('hyperstack', 'policies')))
  end
end