require 'action_controller'

module ReactiveRuby
  module Rails
    class ActionController::Base
      def render_component(*args)
        @component_name = ((args[0].is_a? Hash) || args.empty?) ? params[:action].camelize : args.shift
        @render_params = args.shift || {}
        options = args[0] || {}
        layout = options.key?(:layout) ? options[:layout].to_s : :default
        render inline: "<%= react_component @component_name, @render_params, { prerender: !params[:no_prerender] } %>", layout: layout
      end
    end
  end
end
