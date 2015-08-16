module React

  module Router

    class RR < React::NativeLibrary
      imports ReactRouter
    end

    def self.included(base)
      base.class_eval do

        include React::Component
        include React::IsomorphicHelpers

        before_first_mount do |context|
          if RUBY_ENGINE != 'opal'
            context.eval("window.reactive_router_static_location = '#{context.controller.request.path}?#{context.controller.request.query_string}'")
          else
            @routing = false
          end
        end

        export_component

        def render
          if self.class.routing?
            show
          elsif on_opal_server?
            self.class.routing!
            routes = self.class.build_routes
            %x{
              ReactRouter.run(#{routes}, window.reactive_router_static_location, function(root) {
                self.root = React.createElement(root);
              });
            }
            React::Element.new(@root, 'Root', {}, nil)
          end
        end

        def self.routing?
          @routing
        end

        def self.routing!
          was_routing = @routing
          @routing = true
          was_routing
        end

        after_mount do
          unless self.class.routing!
            dom_node = `React.findDOMNode(#{self}.native)`
            routes = self.class.build_routes
            %x{
              ReactRouter.run(#{routes}, ReactRouter.HistoryLocation, function(root) {
                React.render(React.createElement(root), #{dom_node});
              });
            }
          end
        end

        def self.routes(opts = {}, &block)
          @routes_opts = opts
          @routes_opts[:handler] ||= self
          @routes_block = block
        end
        
        def self.build_routes
          route(@routes_opts, generate_node = true, &@routes_block)
        end

        def self.route(opts = {}, generate_node = nil, &block)
          opts = opts.dup
          opts[:handler] = React::API.create_native_react_class(opts[:handler])
          (generate_node ? RR::Route_as_node(opts, &block) : RR::Route(opts, &block)) 
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

end
