module HyperRouter
  class IsomorphicMethods
    include React::IsomorphicHelpers

    isomorphic_method(:request_fullpath) do |f|
      f.when_on_client { `window.location.pathname` }
      f.send_to_server
      f.when_on_server { f.context.controller.request.fullpath }
    end
  end
end
