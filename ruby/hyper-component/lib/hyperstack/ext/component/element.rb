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
    if `#{to_n}._reactrb_component_class === undefined`
      klass = Class.new
      klass.include Hyperstack::Component
      klass.others :all_the_params
      `#{to_n}._reactrb_component_class = klass`
    else
      klass = `#{to_n}._reactrb_component_class`
    end
    klass.class_eval do
      render(container, params, &block)
    end

    Hyperstack::Component::ReactAPI.render(
      Hyperstack::Component::ReactAPI.create_element(
        klass, container: container, params: params, block: block
      ), self
    )
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

module Hyperstack
  module Internal
    module Component
      module InstanceMethods
        def set_jq(var)
          ->(val) { set(var).call(JQ[val]) }
        end
      end
    end
  end
end

JQ = Element
