require 'native'
require 'active_support/core_ext/object/try'
require 'react/component/tags'
require 'react/component/base'

module React

  ATTRIBUTES = %w(accept acceptCharset accessKey action allowFullScreen allowTransparency alt
                async autoComplete autoPlay cellPadding cellSpacing charSet checked classID
                className cols colSpan content contentEditable contextMenu controls coords
                crossOrigin data dateTime defer dir disabled download draggable encType form
                formAction formEncType formMethod formNoValidate formTarget frameBorder height
                hidden href hrefLang htmlFor httpEquiv icon id label lang list loop manifest
                marginHeight marginWidth max maxLength media mediaGroup method min multiple
                muted name noValidate open pattern placeholder poster preload radioGroup
                readOnly rel required role rows rowSpan sandbox scope scrolling seamless
                selected shape size sizes span spellCheck src srcDoc srcSet start step style
                tabIndex target title type useMap value width wmode dangerouslySetInnerHTML) +
                # SVG ATTRIBUTES
                %w(clipPath cx cy d dx dy fill fillOpacity fontFamily
                fontSize fx fy gradientTransform gradientUnits markerEnd
                markerMid markerStart offset opacity patternContentUnits
                patternUnits points preserveAspectRatio r rx ry spreadMethod
                stopColor stopOpacity stroke  strokeDasharray strokeLinecap
                strokeOpacity strokeWidth textAnchor transform version
                viewBox x1 x2 x xlinkActuate xlinkArcrole xlinkHref xlinkRole
                xlinkShow xlinkTitle xlinkType xmlBase xmlLang xmlSpace y1 y2 y)
  HASH_ATTRIBUTES = %w(data aria)
  HTML_TAGS = React::Component::Tags::HTML_TAGS

  def self.html_tag?(name)
    tags = HTML_TAGS
    %x{
      for(var i = 0; i < tags.length; i++) {
        if(tags[i] === name)
          return true;
      }
      return false;
    }
  end

  def self.html_attr?(name)
    attrs = ATTRIBUTES
    %x{
      for(var i = 0; i < attrs.length; i++) {
        if(attrs[i] === name)
          return true;
      }
      return false;
    }
  end

  def self.create_element(type, properties = {}, &block)
    React::API.create_element(type, properties, &block)
  end

  def self.render(element, container)
    raise "ReactDOM.render is not defined.  In React >= v15 you must import it with ReactDOM" if (`typeof ReactDOM === 'undefined'`)

    container = `container.$$class ? container[0] : container`

    if block_given?
      cb = %x{
      function(){
        setTimeout(function(){
          #{yield}
        }, 0)
      }
    }
      native = `ReactDOM.render(#{element.to_n}, container, cb)`
    else
      native = `ReactDOM.render(#{element.to_n}, container)`
    end

    if `#{native}.__opalInstance !== undefined && #{native}.__opalInstance !== null`
      `#{native}.__opalInstance`
    elsif `ReactDOM.findDOMNode !== undefined && #{native}.nodeType === undefined`
      `ReactDOM.findDOMNode(#{native})`
    else
      native
    end
  end

  def self.is_valid_element(element)
    %x{ console.error("Warning: `is_valid_element` is deprecated in favor of `is_valid_element?`."); }
    element.kind_of?(React::Element) && `React.isValidElement(#{element.to_n})`
  end

  def self.is_valid_element?(element)
    element.kind_of?(React::Element) && `React.isValidElement(#{element.to_n})`
  end

  def self.render_to_string(element)
    %x{ console.error("Warning: `React.render_to_string` is deprecated in favor of `React::Server.render_to_string`."); }
    if !(`typeof ReactDOMServer === 'undefined'`)
      React::RenderingContext.build { `ReactDOMServer.renderToString(#{element.to_n})` } # v0.15+
    else
      raise "renderToString is not defined.  In React >= v15 you must import it with ReactDOMServer"
    end
  end

  def self.render_to_static_markup(element)
    %x{ console.error("Warning: `React.render_to_static_markup` is deprecated in favor of `React::Server.render_to_static_markup`."); }
    if !(`typeof ReactDOMServer === 'undefined'`)
      React::RenderingContext.build { `ReactDOMServer.renderToStaticMarkup(#{element.to_n})` } # v0.15+
    else
      raise "renderToStaticMarkup is not defined.  In React >= v15 you must import it with ReactDOMServer"
    end
  end

  def self.unmount_component_at_node(node)
    if !(`typeof ReactDOM === 'undefined'`)
      `ReactDOM.unmountComponentAtNode(node.$$class ? node[0] : node)` # v0.15+
    else
      raise "unmountComponentAtNode is not defined.  In React >= v15 you must import it with ReactDOM"
    end
  end

end
