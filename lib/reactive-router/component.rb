module React
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
