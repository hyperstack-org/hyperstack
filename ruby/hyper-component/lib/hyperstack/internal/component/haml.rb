require 'hyperstack/ext/component/string'
# see hyperstack/component/haml for this is to be included.
module Hyperstack
  module Internal
    module Component
      module HAMLTagInstanceMethods
        def self.included(base)
          base.const_get('HTML_TAGS').each do |tag|
            if tag == 'p'
              base.define_method(tag) do |*params, &children|
                if children || params.count == 0 || (params.count == 1 && params.first.is_a?(Hash))
                  RenderingContext.render(tag, *params, &children)
                else
                  Kernel.p(*params)
                end
              end
            else
              base.alias_method tag, tag.upcase
            end
          end
        end
      end

      module HAMLElementInstanceMethods
        def method_missing(class_name, args = {}, &new_block)
          return dup.render.method_missing(class_name, args, &new_block) unless rendered?
          Hyperstack::Internal::Component::RenderingContext.replace(
            self,
            Hyperstack::Internal::Component::RenderingContext.build do
              Hyperstack::Internal::Component::RenderingContext.render(type, build_new_properties(class_name, args), &new_block)
            end
          )
        end

        def rendered?
          Hyperstack::Internal::Component::RenderingContext.rendered? self
        end

        def haml_class_name(class_name)
          class_name.gsub(/__|_/, '__' => '_', '_' => '-')
        end

        private

        def build_new_properties(class_name, args)
          class_name = haml_class_name(class_name)
          new_props = @properties.dup
          new_props[:className] = "\
            #{class_name} #{new_props[:className]} #{args.delete(:class)} #{args.delete(:className)}\
          ".split(' ').uniq.join(' ')
          new_props.merge! args
        end
      end
    end
  end
end
