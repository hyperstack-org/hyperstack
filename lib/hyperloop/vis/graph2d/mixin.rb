require 'react/component'

module Hyperloop
  module Vis
    module Graph2d
      module Mixin
        def self.included(base)
          base.include(Hyperloop::Component::Mixin)
          base.class_eval do
            param items: nil
            param groups: nil
            param options: nil

            def _set_dom_node(dom_node)
              @_dom_node = dom_node
            end

            def items
              @_items
            end

            def groups
              @_groups
            end

            def document
              `window.document`
            end

            def options
              @_options
            end

            def automatic_refresh
              true
            end
            
            def self.automatic_refresh(value)
              define_method(:automatic_refresh) do
                value
              end
            end
            
            def self.render_with_dom_node(tag = 'DIV', &block)
              render do
                @_vis_render_block = block
                @_items = params.items
                @_groups = params.groups
                @_options = params.options
                send(tag, ref: method(:_set_dom_node).to_proc)
              end
            end

            def should_component_update?
              `false`
            end

            after_mount do
              if @_dom_node && @_vis_render_block
                instance_exec(@_dom_node, @_items, @_groups, @_options, &@_vis_render_block)
              end
            end

            before_receive_props do |new_props|
              if automatic_refresh && @_dom_node && @_vis_render_block
                changed = false
                if new_props[:items] != @_items
                  @_items = new_props[:items]
                  changed = true
                end
                if new_props[:groups] != @_groups
                  @_items = new_props[:groups]
                  changed = true
                end
                if new_props[:options] != @_options
                  @_options = new_props[:options]
                  changed = true
                end
                if changed
                  instance_exec(@_dom_node, @_items, @_groups, @_options, &@_vis_render_block)
                end
              end
            end
          end
        end
      end
    end
  end
end