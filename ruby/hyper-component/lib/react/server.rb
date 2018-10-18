module Hyperstack
  module Component
    module Server
      def self.render_to_string(element)
        if !(`typeof ReactDOMServer === 'undefined'`)
          Hyperstack::Component::Internal::RenderingContext.build { `ReactDOMServer.renderToString(#{element.to_n})` } # v0.15+
        else
          raise "renderToString is not defined.  In React >= v15 you must import it with ReactDOMServer"
        end
      end

      def self.render_to_static_markup(element)
        if !(`typeof ReactDOMServer === 'undefined'`)
          Hyperstack::Component::Internal::RenderingContext.build { `ReactDOMServer.renderToStaticMarkup(#{element.to_n})` } # v0.15+
        else
          raise "renderToStaticMarkup is not defined.  In React >= v15 you must import it with ReactDOMServer"
        end
      end
    end
  end
end
