module ReactiveRuby
  module ServerRendering
    def self.context_instance_name
      '@context'
    end

    def self.context_instance_for(context)
      context.instance_variable_get(context_instance_name)
    end

    class ContextualRenderer < React::ServerRendering::BundleRenderer
      def initialize(options = {})
        super(options)
        ComponentLoader.new(v8_context).load
      end

      def before_render(*args)
        # the base class clears the log history... we don't want that as it is taken
        # care of in IsomorphicHelpers.load_context
      end

      def render(component_name, props, prerender_options)
        if prerender_options.is_a?(Hash)
          if !v8_runtime? && prerender_options[:context_initializer]
            raise React::ServerRendering::PrerenderError.new(component_name, props, "you must use 'mini_racer' with the prerender[:context] option") unless v8_runtime?
          else
            prerender_options[:context_initializer].call v8_context
            prerender_options = prerender_options[:static] ? :static : true
          end
        end

        super(component_name, props, prerender_options)
      end

      private

      def v8_runtime?
        ExecJS.runtime.name == 'mini_racer (V8)'
      end

      def v8_context
        @v8_context ||= ReactiveRuby::ServerRendering.context_instance_for(@context)
      end
    end
  end
end
