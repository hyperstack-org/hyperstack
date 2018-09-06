if RUBY_ENGINE == 'opal'
  require 'hyperstack/transport/request_agent'
  require 'hyperstack/transport/response_processor'
  require 'hyperstack/transport/notification_processor'
  require 'hyperstack/transport/client_drivers'
  require 'hyperstack/transport'
else
  require 'oj'
  require 'active_support'
  require 'hyperstack/promise'
  require 'hyperstack/transport/config'
  require 'hyperstack/transport/request_agent'
  require 'hyperstack/transport/server_pub_sub'
  require 'hyperstack/transport/request_processor'
  require 'hyperstack/handler'
  require 'hyperstack/transport/rack_middleware'
  Opal.append_path(__dir__.untaint) unless Opal.paths.include?(__dir__.untaint)

  # special treatment for rails
  if defined?(Rails)
    # TODO
    # insert Rack middleware before Rails.app_class.to_s.routes
    module Hyperstack
      module Model
        class Railtie < Rails::Railtie
          def delete_first(a, e)
            a.delete_at(a.index(e) || a.length)
          end

          config.before_configuration do |_|
            Rails.configuration.tap do |config|
              if defined?(Warden::Manager)
                config.middleware.insert_after Warden::Manager, Hyperstack::Transport::RackMiddleware
              else
                config.middleware.use Hyperstack::Transport::RackMiddleware
              end
              config.eager_load_paths += %W(#{config.root}/app/hyperstack/handlers)
              # rails will add everything immediately below app to eager and auto load, so we need to remove it
              delete_first config.eager_load_paths, "#{config.root}/app/hyperstack"

              unless Rails.env.production?
                config.autoload_paths += %W(#{config.root}/app/hyperstack/handlers)
                # rails will add everything immediately below app to eager and auto load, so we need to remove it
                delete_first config.autoload_paths, "#{config.root}/app/hyperstack"
              end
            end
          end
        end
      end
    end
  elsif defined?(Rack)
    if defined?(Warden::Manager)
      config.middleware.insert_after Warden::Manager, Hyperstack::Transport::RackMiddleware
    else
      config.middleware.use Hyperstack::Transport::RackMiddleware
    end
  elsif Dir.exist?(File.join('app', 'hyperstack'))
    $LOAD_PATH.unshift(File.expand_path(File.join('app', 'hyperstack', 'handlers')))
  elsif Dir.exist?(File.join('hyperstack'))
    $LOAD_PATH.unshift(File.expand_path(File.join('hyperstack', 'handlers')))
  end
end
