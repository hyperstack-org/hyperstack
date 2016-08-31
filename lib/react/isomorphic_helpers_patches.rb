module React
  module IsomorphicHelpers
    def self.prerender_footers(controller = nil)
      footer = Context.prerender_footer_blocks.collect { |block| block.call controller }.join("\n")
      if RUBY_ENGINE != 'opal'
        footer = (footer + "#{@context.send_to_opal(:prerender_footers)}") if @context
        footer = footer.html_safe
      end
      footer
    end
  end
end

module ReactiveRuby
  module Rails
    class ComponentMount < React::Rails::ComponentMount
      def footers
        React::IsomorphicHelpers.prerender_footers(controller) #if options[:prerender]
      end
    end
  end
end
