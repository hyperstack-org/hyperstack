module React

  # class RR < React::NativeLibrary
  #   imports ReactRouter
  # end

  class Router

    include React::Component

    def route(*args, &children)
      DSL::Route.new(*args, &children)
    end

    def index(opts = {})
      DSL::Index.new(opts)
    end

    def redirect(from, opts={})
      DSL::Route.new(opts.merge(path: from)).on(:enter) { |c| c.replace(opts[:to]) }
    end

    def index_redirect(opts={})
      DSL::Index.new(opts).on(:enter) { |c| c.replace(opts[:to])}
    end

    def build_routes(&block)
      React::Router::DSL.build_routes(&block)
    end

    def hash_history
      `window.ReactRouter.hashHistory`
    end

    def browser_history
      `window.ReactRouter.browserHistory`
    end

    def gather_params
      params = {routes: React::Router::DSL.children_to_n(build_routes { routes })}
      params[:history] = history if respond_to? :history
      [:create_element, :stringify_query, :parse_query_string, :on_error, :on_update].each do |method|
        params[method.camelcase(false)] = send("#{method}_wrapper") if respond_to? method
      end
      params
    end

    def render
      Native::Router(gather_params)
    end

    #private

    class Native < React::NativeLibrary
      imports ReactRouter
    end

    def stringify_query_wrapper
      lambda { |q| stringify_query(Hash.new(q)) }
    end

    def on_update_wrapper
      lambda { on_update(Hash.new(`this.props`), Hash.new(`this.state`)) }
    end

    def create_element_wrapper
      lambda do |component, props|
        comp_classes = React::API.class_eval { @@component_classes }
        rb_component = comp_classes.detect { |key, value| value == component }.first
        # not sure if this could ever happen, could not figure out a way to test it so commented it out
        # unless rb_component
        #   rb_component = Class.new(React::Component::Base)
        #   comp_classes[rb_component] = component
        # end
        rb_props = {
          children: `props.children`,
          history: `props.history`,
          location: `props.location`,
          params: `props.params`,
          route: `props.route`,
          route_params: `props.route_params`,
          routes: `props.routes`
        }
        result = create_element(rb_component, rb_props)
        is_result_native_react_element = `!!result._isReactElement`
        if is_result_native_react_element
          result
        elsif !result
          `React.createElement(component, props)`
        elsif result.is_a? React::Element
          result.to_n
        else
          React.create_element(rb_component, rb_props).to_n
        end
      end
    end

    def on_error_wrapper
      lambda do |message|
        on_error(message)
      end
    end

  end
end
