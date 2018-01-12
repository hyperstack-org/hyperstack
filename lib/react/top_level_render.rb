module React
  def self.render(element, container)
    container = `container.$$class ? container[0] : container`

    cb = %x{
      function(){
        setTimeout(function(){
          #{yield if block_given?}
        }, 0)
      }
    }

    raise "ReactDOM.render is not defined.  In React >= v15 you must import it with ReactDOM" if (`typeof ReactDOM === 'undefined'`)
    native = `ReactDOM.render(#{element.to_n}, container, cb)`

    if `#{native}._getOpalInstance !== undefined`
      `#{native}._getOpalInstance()`
    elsif `ReactDOM.findDOMNode !== undefined && #{native}.nodeType === undefined`
      `ReactDOM.findDOMNode(#{native})`
    else
      native
    end
  end
end
