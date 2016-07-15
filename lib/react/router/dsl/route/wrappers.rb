module React
  class Router
    class DSL
      class Route
        def get_child_routes_wrapper
          lambda do |location, callBack|
            children, index, promise =
              React::Router::DSL.evaluate_children(TransitionContext.new(location: location),
                                                   &@get_children)
            if promise.class < Promise
              promise.then do |children|
                callBack.call(nil.to_n, React::Router::DSL.children_to_n(children))
              end.fail { |err_object| callBack.call(err_object, nil.to_n) }
            else
              callBack.call(nil.to_n, DSL.children_to_n(children))
            end
          end
        end

        def get_components_wrapper
          lambda do |nextState, callBack|
            result_hash = {}
            promises = []
            @components.each do |name, proc_or_comp|
              if proc_or_comp.respond_to? :call
                comp = proc.call(TransitionContext.new(next_state: nextState))
                if comp.class < Promise
                  promises << comp
                  comp.then do |component|
                    result_hash[name] = React::API.create_native_react_class(component)
                  end.fail { |err_object| `callBack(#{err_object}, null)` }
                else
                  result_hash[name] = React::API.create_native_react_class(comp)
                end
              else
                result_hash[name] = React::API.create_native_react_class(proc_or_comp)
              end
            end
            Promise.when(*promises).then { `callBack(null, #{result_hash.to_n})` }
          end.to_n
        end

        def get_component_wrapper
          lambda do |nextState, callBack|
            comp = @component.call(TransitionContext.new(next_state: nextState))
            if comp.class < Promise
              comp.then do |component|
                component = React::API.create_native_react_class(component)
                `callBack(null, component)`
              end.fail { |err_object| `callBack(#{err_object}, null)` }
            else
              comp = React::API.create_native_react_class(comp)
              `callBack(null, comp)`
            end
          end.to_n
        end

        def on_enter_wrapper
          lambda do |nextState, replace, callBack|
            comp =
              @opts[:on_enter].call(TransitionContext.new(next_state: nextState, replace: replace))
            if comp.class < Promise
              comp.then { `callBack()` }
            else
              `callBack()`
            end
          end.to_n
        end

        def on_change_wrapper(proc)
          lambda do |prevState, nextState, replace, callBack|
            comp = @opts[:on_change].call(TransitionContext.new(prev_state: prevState,
                                                                next_state: nextState,
                                                                replace: replace))
            if comp.class < Promise
              comp.then { `callBack()` }
            else
              `callBack()`
            end
          end.to_n
        end

        def on_leave_wrapper(proc)
          lambda do
            @opts[:on_leave].call(TransitionContext.new)
          end.to_n
        end

        def get_index_route_wrapper
          lambda do |location, callBack|
            comp = @opts[:index].call(TransitionContext.new(location: location))
            if comp.class < Promise
              comp.then { |component| `callBack(null, {component: #{component}})` }
                  .fail { |err_object| `callBack(#{err_object}, null)` }
            else
              `callBack(null, {component: #{comp}})`
            end
          end.to_n
        end
      end
    end
  end
end
