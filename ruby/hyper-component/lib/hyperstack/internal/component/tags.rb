module Hyperstack
  module Internal
    module Component    # contains the name of all HTML tags, and the mechanism to register a component
      # class as a new tag
      module Tags
        HTML_TAGS = %w(a abbr address area article aside audio b base bdi bdo big blockquote body br
                       button canvas caption cite code col colgroup data datalist dd del details dfn
                       dialog div dl dt em embed fieldset figcaption figure footer form h1 h2 h3 h4 h5
                       h6 head header hr html i iframe img input ins kbd keygen label legend li link
                       main map mark menu menuitem meta meter nav noscript object ol optgroup option
                       output p param picture pre progress q rp rt ruby s samp script section select
                       small source span strong style sub summary sup table tbody td textarea tfoot th
                       thead time title tr track u ul var video wbr) +
                    # The SVG Tags
                    %w(circle clipPath defs ellipse g line linearGradient mask path pattern polygon polyline
                    radialGradient rect stop svg text tspan)

        # the present method is retained as a legacy behavior
        # def present(component, *params, &children)
        #   RenderingContext.render(component, *params, &children)
        # end

        # define each predefined tag (upcase) as an instance method and a constant
        # deprecated: define each predefined tag (downcase) as the alias of the instance method

        HTML_TAGS.each do |tag|

          define_method(tag.upcase) do |*params, &children|
            RenderingContext.render(tag, *params, &children)
          end

          const_set tag.upcase, tag
        end

        # this is used for haml style (i.e. DIV.foo.bar) class tags which is deprecated
        def self.html_tag_class_for(tag)
          downcased_tag = tag.downcase
          if tag =~ /^[A-Z]+$/ && HTML_TAGS.include?(downcased_tag)
            Object.const_set tag, ReactWrapper.create_element(downcased_tag)
          end
        end

        # use method_missing to look up component names in the form of "Foo(..)"
        # where there is no preceeding scope.

        def method_missing(name, *params, &children)
          component = find_component(name)
          return RenderingContext.render(component, *params, &children) if component
          super
        end

        # install methods with the same name as the component in the parent class/module
        # thus component names in the form Foo::Bar(...) will work

        class << self
          def included(component)
            name, parent = find_name_and_parent(component)
            tag_names_module = Module.new do
              define_method name do |*params, &children|
                RenderingContext.render(component, *params, &children)
              end
            end
            parent.extend(tag_names_module)
          end

          private

          def find_name_and_parent(component)
            split_name = component.name && component.name.split('::')
            if split_name && split_name.length > 1
              [split_name.last, split_name.inject([Module]) { |a, e| a + [a.last.const_get(e)] }[-2]]
            end
          end
        end

        private

        def find_component(name)
          component = lookup_const(name)
          if component && !component.method_defined?(:render)
            raise "#{name} does not appear to be a react component."
          end
          component || Object._reactrb_import_component_class(name)
        end

        def lookup_const(name)
          return nil unless name =~ /^[A-Z]/
          scopes = self.class.name.to_s.split('::').inject([Object]) do |nesting, next_const|
            nesting + [nesting.last.const_get(next_const)]
          end.reverse
          scope = scopes.detect { |s| s.const_defined?(name, false) }
          scope.const_get(name, false) if scope
        end
      end
    end
  end
end

unless Object.respond_to? :_reactrb_import_component_class
  class Object
    def self._reactrb_import_component_class(_name)
      nil
    end
  end
end
