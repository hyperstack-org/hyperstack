
module React

  module Router

    class AbortTransition < Exception
    end

    class RR < React::NativeLibrary
      imports ReactRouter
    end

    def self.included(base)
      base.class_eval do

        include React::Component
        include React::IsomorphicHelpers

        native_mixin `ReactRouter.Navigation`
        native_mixin `ReactRouter.State`

        class << self

          attr_accessor :router_context

          def get_path
            path = `#{@router_component}.native.getPath()`
            path = nil if `typeof path === 'undefined'`
            path
          end

          def replace_with(route_or_path, params = nil, query = nil)
            `#{@router_component}.native.replaceWith.apply(self.native, #{[route_or_path, params, query].compact})`
          end

          def transition_to(route_or_path, params = {}, query = {})
            params = @router_component.params[:router_state][:params].merge params
            query = @router_component.params[:router_state][:query].merge query
            `#{@router_component}.native.transitionTo.apply(self.native, #{[route_or_path, params.to_n, query.to_n]})`
          end

          def link(opts={}, &block)
            params = opts.delete(:params) || {}
            query = opts.delete(:query) || {}
            to = opts.delete(:to)
            React::RenderingContext.render("a", opts, &block).on(:click) { transition_to(to, params, query) }
          end

          def url_param_methods
            @url_param_methods ||= []
          end

          attr_accessor :evaluated_url_params
          attr_accessor :current_url_params

          def router_param(name, opts = {}, &block)

            # create a method visible both the instance and the class
            # that gets passed the named router parameter (typically a db :id) and returns a
            # meaningful value (typically a database record)

            method_name = opts[:as] || name

            class << self
              define_method method_name do
                if @router_component
                  block.call @router_component.url_params[name]
                else
                  raise "Call to #{self.name}.#{method_name} when #{self.name} is not mounted"
                end
              end
            end

            define_method method_name do
              self.class.send method_name
            end

          end

        end

        static_call_back "willTransitionTo" do |transition, params, query, callback|
          params = Hash.new(params)
          query = Hash.new(query)
          transition = `transition.path`
          puts "willTransitionTo(#{transition}, #{params}, #{query}) for router #{self.object_id}, router_component = #{@router_component.object_id}"
          begin
            if self.respond_to? :will_transition_to
              result = will_transition_to transition, params, query if self.respond_to? :will_transition_to
              if result.is_a? Promise
                result.then { |r| callback(r) }
              else
                callback.call()
              end
            else
              callback.call()
            end
          rescue AbortTransition
            raise "transition aborted"
          end
        end

        before_first_mount do |context|

          @evaluated_url_params = {}
          @current_url_params = {}
          if !self.instance_methods.include?(:show)  # if there is no show method this is NOT a top level router so we assume routing will begin elsewhere
            @routing = true
          elsif `typeof ReactRouter === 'undefined'`
            if on_opal_client?
              message = "ReactRouter not defined in browser assets - you must manually include it in your assets"
            else
              message = "ReactRouter not defined in components.js.rb assets manifest - you must manually include it in your assets"
            end
            `console.error(message)`
            @routing = true
          else
            @routing = false
          end
        end

        export_component

        param :router_state # optional because it is not initially passed in but we add it when running the router
        param :query
        param :params

        def url_params(params = params)
          (params && (params[:params] || (params[:router_state] && params[:router_state][:params]))) || {}
        end

        def render
          if self.class.routing?
            if self.class.router_context
              `self.native.context.router = #{self.class.router_context}`
            else
              self.class.router_context = `self.native.context.router`
            end
            self.class.instance_variable_set(:@router_component, self)  # this was done after mount, but I think it works here
            show
          elsif on_opal_server?
            self.class.routing!
            routes = self.class.build_routes(true)
            %x{
              ReactRouter.run(#{routes}, window.reactive_router_static_location, function(root, state) {
                self.native.props.router_state = state
                self.root = React.createElement(root, self.native.props);
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

        # override self.location to provide application specific location handlers

        def location
          (@location ||= History.new("MainApp")).activate.location  # must be called MainApp for now to avoid doing an extra state push (ugh)
        end

        after_mount do
          if !self.class.routing!
            puts "after mount outside of ruby router #{self.object_id}, my class router is #{self.class.object_id}"
            dom_node = if `typeof React.findDOMNode === 'undefined'`
              `#{self}.native.getDOMNode`            # v0.12.0
            else
              `React.findDOMNode(#{self}.native)`    # v0.13.0
            end
            routes = self.class.build_routes(true)
            %x{
              ReactRouter.run(#{routes}, #{location}, function(root, state) {
                self.native.props.router_state = state
                React.render(React.createElement(root, self.native.props), #{dom_node});
              });
            }
          elsif respond_to? :show
            puts "after mount inside of ruby router #{self.object_id}, my class router is #{self.class.object_id}"
            #self.class.instance_variable_set(:@router_component, self)  # this was done here but was moved to the first render
          end
        end

        def self.routes(opts = {}, &block)
          @routes_opts = opts
          @routes_block = block
        end

        def self.routes_block
          @routes_block
        end

        def self.build_routes(generate_node = nil)
          #raise "You must define a routes block in a router component" unless @routes_block
          routes_opts = @routes_opts.dup
          routes_opts[:handler] ||= self
          route(routes_opts, generate_node, &@routes_block)
        end

        def self.route(opts = {}, generate_node = nil, &block)
          block ||= opts[:handler].routes_block if opts[:handler].respond_to? :routes_block
          opts = opts.dup
          opts[:handler] = React::API.create_native_react_class(opts[:handler])
          (generate_node ? RR::Route_as_node(opts, &block) : RR::Route(opts, &block))
        rescue Exception => e
          React::IsomorphicHelpers.log("Could not define route #{opts}: #{e}", :error)
        end

        def self.default_route(ops = {}, &block)
          RR::DefaultRoute(opts, &block)
        end

        def self.redirect(opts = {}, &block)
          RR::Redirect(opts, &block)
        end

        def self.not_found(opts={}, &block)
          opts[:handler] = React::API.create_native_react_class(opts[:handler])
          RR::NotFoundRoute(opts, &block)
        end

      end
    end

  end

end
