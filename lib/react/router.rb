module React

  class RR < React::NativeLibrary
    imports ReactRouter
  end

  class Router

    include React::Component

    def build_routes
      React::Router::DSL.evaluate_children { routes }[0].collect do |element|
        element.to_json.to_n
      end
    end

    def route(*args, &children)
      DSL::Route.new(*args, &children)
    end

    def index(opts = {})
      DSL::Index.new(opts)
    end

    def redirect(from, opts={})
      DSL::Redirect.new(from, opts)
    end

    def index_redirect(opts={})
      DSL::IndexRedirect.new(opts)
    end

    def add_param_if_defined(params, method, param)
      params[param] = lambda { |*args| method(*args) } if self.respond_to? method
    end

    def gather_params
      params = {routes: build_routes}
      [:history, :create_element, :stringify_query, :parse_query_string, :on_error, :on_update].each do |method|
        add_param_if_defined(params, method, method.camelcase(false))
      end
      add_param_if_defined(params, :on_render, "render")
      params
    end

    def render
      RR::Router(gather_params)
    end
  end
end
