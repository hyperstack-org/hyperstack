module HyperSpec
  module RailsControllerHelpers
    def self.included(base)
      base.include ControllerHelpers
      base.include Helpers
      routes = ::Rails.application.routes
      routes.disable_clear_and_finalize = true
      routes.clear!
      routes.draw { get "/#{base.route_root}/:id", to: "#{base.route_root}#test" }
      ::Rails.application.routes_reloader.paths.each { |path| load(path) }
      routes.finalize!
      ActiveSupport.on_load(:action_controller) { routes.finalize! }
    ensure
      routes.disable_clear_and_finalize = false
    end

    module Helpers
      def ping!
        head(:no_content)
        nil
      end

      def mount_component!
        @page = '<%= react_component @component_name, @component_params, '\
                "{ prerender: #{@render_on != :client_only} } %>\n#{@page}"
      end

      def application!(file)
        @page = "<%= javascript_include_tag '#{file}' %>\n#{@page}"
      end

      def style_sheet!(file)
        @page = "<%= stylesheet_link_tag '#{file}' %>\n#{@page}"
      end

      def deliver!
        @render_params[:inline] = @page
        response.headers['Cache-Control'] = 'max-age=120'
        response.headers['X-Tracking-ID'] = '123456'
        render @render_params
      end

      def server_only?
        @render_on == :server_only
      end
    end
  end
end
