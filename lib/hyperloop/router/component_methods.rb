# rubocop:disable Style/MethodName

module Hyperloop
  class Router
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
        React::Router::DOM::NavLink(opts, &children)
      end

      def Redirect(to, opts = {})
        opts[:to] = to.to_n
        React::Router::Redirect(opts)
      end

      def Route(to, opts = {}, &block)
        opts[:path] = to.to_n
        if opts[:mounts]
          component = opts.delete(:mounts)
          opts[:component] = ->(e) { React.create_element(component, match: `#{e}.match`).to_n }
        end

        if block
          opts[:render] = lambda do |e|
            params = ::Hash.new(`#{e}.match`)
            yield(params).to_n
          end
        end

        React::Router::Route(opts)
      end

      def Switch(&children)
        React::Router::Switch(&children)
      end
    end
  end
end
