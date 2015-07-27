require 'opal'
require 'opal-react'
require 'react-router-rails'

module React

  module Router

    class RR < React::NativeLibrary
      imports ReactRouter
    end

    def self.included(base)
      base.class_eval do

        include React::Component

        backtrace :on

        export_component

        def render
          show if self.class.routing?
        end

        def self.routing?
          @routing
        end

        def self.routing!
          was_routing = @routing
          @routing = true
          was_routing
        end

        def self.handler(handler)
          React::API.create_native_react_class(handler)
        end

        after_mount do
          unless self.class.routing!
            x = `React.findDOMNode(#{self}.native)`
            routes = self.class.class_eval { @routes.call }
            %x{
              ReactRouter.run(#{routes}, ReactRouter.HistoryLocation, function(root) {
                React.render(React.createElement(root), #{x});
              });
            }
          end
        end

        def self.routes(opts = {}, &block)
          opts[:handler] ||= self
          @routes = -> { self.route(opts, generate_node = true, &block) }
        end

        def self.route(opts = {}, generate_node = nil, &block)
          opts[:handler] = self.handler(opts[:handler])
          generate_node ? RR::Route_as_node(opts, &block) : RR::Route(opts, &block)
        end

        def self.default_route(ops = {}, &block)
          RR::DefaultRoute(opts, &block)
        end

        def self.redirect(opts = {}, &block)
          RR::Redirect(opts, &block)
        end

      end
    end

  end

  module Component

    module ClassMethods

      def router_param(name, &block)
        define_state name
        before_mount do
          send("#{name}!", yield(params[:params][name]))
        end
        before_receive_props do |new_params|
          send("#{name}!", yield(new_params[:params][name]))
        end
      end

    end

    def route_handler
      Router::RR::RouteHandler()
    end

    def link(opts = {}, &block)
      opts[:params] = opts[:params].to_n if opts[:params]
      Router::RR::Link(opts, &block)
    end

  end

end
