module React
  module Server
    def self.render_to_string(element)
      if !(`typeof ReactDOMServer === 'undefined'`)
        React::RenderingContext.build { `ReactDOMServer.renderToString(#{element.to_n})` } # v0.15+
      elsif !(`typeof React.renderToString === 'undefined'`)
        React::RenderingContext.build { `React.renderToString(#{element.to_n})` }
      else
        raise "renderToString is not defined.  In React >= v15 you must import it with ReactDOMServer"
      end
    end

    def self.render_to_static_markup(element)
      if !(`typeof ReactDOMServer === 'undefined'`)
        React::RenderingContext.build { `ReactDOMServer.renderToStaticMarkup(#{element.to_n})` } # v0.15+
      elsif !(`typeof React.renderToString === 'undefined'`)
        React::RenderingContext.build { `React.renderToStaticMarkup(#{element.to_n})` }
      else
        raise "renderToStaticMarkup is not defined.  In React >= v15 you must import it with ReactDOMServer"
      end
    end
  end
end
