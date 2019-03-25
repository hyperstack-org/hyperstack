require 'action_controller'

module Hyperstack
  module Internal
    module Component
      class Redirect < StandardError
        attr_reader :url
        def initialize(url)
          @url = url
          super("redirect to #{url}")
        end
      end
    end
  end
end

module ActionController
  # adds render_component helper to ActionControllers
  class Base
    def render_component(*args)
      @component_name = (args[0].is_a? Hash) || args.empty? ? params[:action].camelize : args.shift
      @render_params = args.shift || {}
      options = args[0] || {}
      return if performed?
      render inline: '<%= react_component @component_name, @render_params %>',
             layout: options.key?(:layout) ? options[:layout].to_s : :default
    rescue Exception => e
      m = /^RuntimeError: Hyperstack::Internal::Component::Redirect (.+) status: (.+)$/.match(e.message)
      raise e unless m
      redirect_to m[1], status: m[2]
    end
  end
end
