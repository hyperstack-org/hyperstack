module React
  module Router
    class WindowLocation
      
      include React::IsomorphicHelpers
      
      before_first_mount do |context|
        context.eval("window.reactive_router_static_location = '#{context.controller.request.path}?#{context.controller.request.query_string}'")
      end

    end
  end
end