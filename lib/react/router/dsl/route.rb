module React
  class Router
    class DSL
      class Route

        def initialize(*args, &children)
          path = if args[0].is_a? Hash
            nil
          else
            args[0]
          end
          opts = if args[0].is_a? Hash
            args[0]
          else
            args[1] || {}
          end
          unless opts.is_a? Hash
            raise "Route expects an optional path followed by an options hash, instead we got route(#{'"'+path+'", ' if path} #{opts})"
          end
          @children, @index = DSL.evaluate_children do
            children.call if children
            Index.new(mounts: opts[:index]) if opts[:index]
          end
          @path = path
          if opts[:mounts].is_a? Hash
            @components = opts[:mounts]
          else
            @component = opts[:mounts]
          end
          opts[:mounts] = nil
          @opts = opts
          save_element
        end

        def save_element
          DSL.add_element(self)
        end

        def on(hook, &block)
          @opts[hook] = block
        end

        def mounts(name=nil, &block)
          if name
            @components ||= {}
            @components[name] = block
          else
            @component = block
          end
        end

        def to_json
          hash = {}
          hash[:path] = @path if @path

          if @components
            if @components.detect { |k, v| v.respond_to? :call }
              hash[:getComponents] = get_components_wrapper
            else
              hash[:components] = @components
            end
          elsif @component.respond_to? :call
            hash[:getComponent] = get_component_wrapper
          elsif @component
            hash[:component] = React::API::create_native_react_class(@component)
          else
            hash[:component] = DSL.router.lookup_component(@path)
          end

          [:on_enter, :on_change, :on_leave].each do |hook|
            hash[hook.camelcase(false)] = send("#{hook}_wrapper") if @opts[hook]
          end

          hash[:indexRoute] = @index.to_json if @index

          hash[:childRoutes] = @children.collect { |child| child.to_json }

          hash
        end

        def get_components_wrapper
          lambda do | nextState, callBack |
            result_hash = {}
            promises = []
            @components.each do |name, proc_or_comp|
              if proc_or_comp.respond_to? :call
                comp = proc.call(TransitionContext.new(next_state: nextState))
                if comp.class < Promise
                  promises << comp
                  comp.
                  then { |component| result_hash[name] = React::API::create_native_react_class(component) }.
                  fail { |message| `callBack(#{message.to_n}, null)`}
                else
                  result_hash[name] = React::API::create_native_react_class(comp)
                end
              else
                result_hash[name] = React::API::create_native_react_class(proc_or_comp)
              end
            end
            Promise.when(*promises).then { `callBack(null, #{result_hash.to_n})` }
          end.to_n
        end

        def get_component_wrapper
          lambda do | nextState, callBack |
            comp = @component.call(TransitionContext.new(next_state: nextState))
            if comp.class < Promise
              comp.then do |component|
                component = React::API::create_native_react_class(component)
                `callBack(null, component)`
              end.fail { |message| `callBack(#{message.to_n}, null)` }
            else
              comp = React::API::create_native_react_class(comp)
              `callBack(null, comp)`
            end
          end.to_n
        end

        def on_enter_wrapper
          lambda do | nextState, replace, callBack |
            comp = @opts[:on_enter].call(TransitionContext.new(next_state: nextState, replace: replace))
            if comp.class < Promise
              comp.then { `callBack()` }
            else
              `callBack()`
            end
          end.to_n
        end

        def on_change_wrapper(proc)
          lambda do | prevState, nextState, replace, callBack |
            comp = @opts[:on_change].call(TransitionContext.new(prev_state: prevState, next_state: nextState, replace: replace))
            if comp.class < Promise
              comp.then { `callBack()` }
            else
              `callBack()`
            end
          end.to_n
        end

        def on_leave_wrapper(proc)
          lambda do
            comp = @opts[:on_leave].call(TransitionContext.new)
            if comp.class < Promise
              comp.then { `callBack()` }
            else
              `callBack()`
            end
          end.to_n
        end

        def index_wrapper
          lambda do | location, callBack |
            comp = @opts[:index].call(TransitionContext.new(location: location))
            if comp.class < Promise
              comp.
              then { |component| `callBack(null, {component: #{component}})` }.
              fail { |message| `callBack(#{message.to_n}, null)` }
            else
              `callBack(null, {component: #{comp}})`
            end
          end.to_n
        end
      end
    end
  end
end
