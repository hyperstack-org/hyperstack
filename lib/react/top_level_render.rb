module React
  def self.render(element, container)
    container = `container.$$class ? container[0] : container`
    if !(`typeof ReactDOM === 'undefined'`)
      native = `ReactDOM.render(#{element.to_n}, container, function(){#{yield if block_given?}})` # v0.15+
    elsif !(`typeof React.renderToString === 'undefined'`)
      native = `React.render(#{element.to_n}, container, function(){#{yield if block_given?}})`
    else
      raise "render is not defined.  In React >= v15 you must import it with ReactDOM"
    end

    if `#{native}._getOpalInstance !== undefined`
      `#{native}._getOpalInstance()`
    elsif `React.findDOMNode !== undefined && #{native}.nodeType == undefined`
      `React.findDOMNode(#{native})`
    else
      native
    end
  end
end
