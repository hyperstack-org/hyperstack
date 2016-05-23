module React
  class Router
    class DSL
      class Route

        def on(hook, &block)
          @opts["on_#{hook}"] = block
          self
        end

        def mounts(name=nil, &block)
          if name
            @components ||= {}
            @components[name] = block
          else
            @component = block
          end
        end
        
      end
    end
  end
end
