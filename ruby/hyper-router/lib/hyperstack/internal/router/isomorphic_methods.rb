module Hyperstack
  module Internal
    module Router
      class IsomorphicMethods
        include Hyperstack::Component::IsomorphicHelpers

        isomorphic_method(:request_fullpath) do |f|
          f.when_on_client { `window.location.pathname` }
          f.send_to_server
          f.when_on_server { f.context.controller.request.fullpath }
        end
      end
    end
  end
end
