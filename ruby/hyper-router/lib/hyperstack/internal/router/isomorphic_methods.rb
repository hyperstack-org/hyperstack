module Hyperstack
  module Internal
    module Router
      class IsomorphicMethods
        include Hyperstack::Component::IsomorphicHelpers

        def self.ctx
          @ctx ||= `{}`
        end

        prerender_footer do |_controller|
          next unless on_opal_server?
          ctx_as_hash = Hash.new(@ctx)
          @ctx = `{}`
          raise "Hyperstack::Internal::Component::Redirect #{ctx_as_hash[:url]} status: #{ctx_as_hash[:status]}" if ctx_as_hash[:url]
        end

        isomorphic_method(:request_fullpath) do |f|
          f.when_on_client { `window.location.pathname` }
          f.send_to_server
          f.when_on_server { f.context.controller.request.fullpath }
        end
      end
    end
  end
end
