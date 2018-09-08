require 'action_controller'

module ActionController
  # adds render_component helper to ActionControllers
  class Base
    def render_component(*args)
      @component_name = (args[0].is_a? Hash) || args.empty? ? params[:action].camelize : args.shift
      @render_params = args.shift || {}
      options = args[0] || {}
      render inline: '<%= react_component @component_name, @render_params %>',
             layout: options.key?(:layout) ? options[:layout].to_s : :default
    end
  end
end
