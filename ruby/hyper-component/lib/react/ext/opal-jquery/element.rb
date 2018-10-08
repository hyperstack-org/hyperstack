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
    # create an invisible component class and hang it off the DOM element
    if `#{self.to_n}._reactrb_component_class === undefined`
      klass = Class.new(Hyperloop::Component) do
        # react won't rerender the components unless it sees some params
        # changing, so we just copy them all in, but we still just reuse
        # the render macro to define the action
        others :all_the_params
      end
      `#{self.to_n}._reactrb_component_class = #{klass}`
    else
      klass = `#{self.to_n}._reactrb_component_class`
    end
    # define / redefine the render method
    klass.render(container, params, &block)
    React.render(React.create_element(klass, {container: container, params: params, block: block}), self)
  end

  # mount_components is useful for dynamically generated page segments for example
  # see react-rails documentation for more details

  %x{
    $.fn.mount_components = function() {
      this.each(function(e) { ReactRailsUJS.mountComponents(e[0]) })
      return this;
    }
  }
  Element.expose :mount_components
end
