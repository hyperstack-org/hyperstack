require 'react/router/dsl/route/hooks'
require 'react/router/dsl/route/wrappers'

module React
  class Router
    class DSL
      class Route
        def initialize(*args, &children)
          path =
            if args[0].is_a? Hash
              nil
            else
              args[0]
            end
          opts =
            if args[0].is_a? Hash
              args[0]
            else
              args[1] || {}
            end
          unless opts.is_a? Hash
            raise 'Route expects an optional path followed by an options hash, '\
                  "instead we got route(#{'"' + path + '", ' if path} #{opts})"
          end
          @children, @index = DSL.evaluate_children do
            yield if children && children.arity == 0
            Index.new(mounts: opts[:index]) if opts[:index]
          end
          opts.delete(:index)
          @get_children = children if children && children.arity > 0
          @path = path
          if opts[:mounts].is_a? Hash
            @components = opts[:mounts]
          else
            @component = opts[:mounts]
          end
          opts.delete(:mounts)
          @opts = opts
          save_element
        end

        def save_element
          DSL.add_element(self)
        end

        def to_json
          hash = {}
          hash[:path] = @path if @path

          if @get_children
            hash[:getChildRoutes] = get_child_routes_wrapper
          else
            hash[:childRoutes] = @children.map(&:to_json)
          end

          if @components
            if @components.detect { |_k, v| v.respond_to? :call }
              hash[:getComponents] = get_components_wrapper
            else
              hash[:components] = @components
            end
          elsif @component.respond_to? :call
            hash[:getComponent] = get_component_wrapper
          elsif @component
            hash[:component] = React::API.create_native_react_class(@component)
          else
            hash[:component] = DSL.router.lookup_component(@path)
          end

          %w(enter change leave).each do |hook|
            hash["on#{hook.camelcase}"] = send("on_#{hook}_wrapper") if @opts["on_#{hook}"]
          end

          if @index.respond_to? :call
            hash[:getIndexRoute] = get_index_route_wrapper
          elsif @index
            hash[:indexRoute] = @index.to_json
          end

          @opts.each do |key, value|
            hash[key] = value unless %w(on_enter on_change on_leave).include?(key)
          end

          hash
        end
      end
    end
  end
end
