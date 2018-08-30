# rubocop:disable Style/MethodName

module HyperRouter
  module ComponentMethods
    def Link(to, opts = {}, &children)
      opts[:to] = {}.tap do |hash|
        hash[:pathname] = to
        hash[:search] = opts.delete(:search) if opts[:search]
        hash[:hash] = opts.delete(:hash) if opts[:hash]
      end.to_n
      React::Router::DOM::Link(opts, &children)
    end

    def NavLink(to, opts = {}, &children)
      opts[:to] = to.to_n
      opts[:activeClassName] = opts.delete(:active_class).to_n if opts[:active_class]
      opts[:activeStyle] = opts.delete(:active_style).to_n if opts[:active_style]
      opts[:isActive] = opts.delete(:active).to_n if opts[:active]
      if (%i[activeClassName activeStyle isActive] & opts.keys).any?
        React::State.get_state(HyperRouter, :location)
      end
      React::Router::DOM::NavLink(opts, &children)
    end

    def Redirect(to, opts = {})
      opts[:to] = to.to_n
      React::Router::Redirect(opts)
    end

    def format_params(e)
      {
        match:    HyperRouter::Match.new(`#{e}.match`),
        location: HyperRouter::Location.new(`#{e}.location`),
        history:  HyperRouter::History.new(`#{e}.history`)
      }
    end

    def Route(to, opts = {}, &block)
      opts[:path] = to.to_n

      if opts[:mounts]
        component = opts.delete(:mounts)

        opts[:component] = lambda do |e|
          route_params = format_params(e)

          React.create_element(component, route_params).to_n
        end
      end

      if block
        opts[:render] = lambda do |e|
          route_params = format_params(e)

          yield(route_params.values).to_n
        end
      end

      React::Router::Route(opts)
    end

    def Switch(&children)
      React::Router::Switch(&children)
    end
  end
end
