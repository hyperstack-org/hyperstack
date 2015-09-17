module React
  module Component

    module ClassMethods



    end

    def route_handler(*args)
      Router::RR::RouteHandler(*args)
    end

    def link(opts = {}, &block)
      opts[:params] = opts[:params].to_n if opts[:params]
      Router::RR::Link(opts, &block)
    end

  end
end
