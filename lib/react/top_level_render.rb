module React
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
    
    if `#{native}._getOpalInstance !== undefined && #{native}._getOpalInstance !== null`
      `#{native}._getOpalInstance()`
    elsif `ReactDOM.findDOMNode !== undefined && #{native}.nodeType === undefined`
      `ReactDOM.findDOMNode(#{native})`
    else
      native
    end
  end
end
