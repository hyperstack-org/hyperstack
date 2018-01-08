Element.instance_eval do
  def self.find(selector)
    selector = begin
      selector.dom_node
    rescue
      selector
    end if `#{selector}.$dom_node !== undefined`
    `$(#{selector})`
  end

  def self.[](selector)
    find(selector)
  end

  define_method :render do |container = nil, params = {}, &block|
    if `#{self.to_n}._reactrb_component_class === undefined`
      `#{self.to_n}._reactrb_component_class = #{Class.new(Hyperloop::Component)}`
    end
    klass = `#{self.to_n}._reactrb_component_class`
    klass.class_eval do
      render(container, params, &block)
    end

    React.render(React.create_element(`#{self.to_n}._reactrb_component_class`), self)
  end
end if Object.const_defined?('::Element')
