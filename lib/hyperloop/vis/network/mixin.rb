require 'react/component'

module Hyperloop
  module Vis
    module Network
      module Mixin
        def self.included(base)
          base.include(Hyperloop::Component::Mixin)
          base.class_eval do
            param vis_data: nil
            param options: nil

            def _set_dom_node(dom_node)
              @_dom_node = dom_node
            end

            def data
              @_data
            end

            def document
              `window.document`
            end

            def options
              @_options
            end

            def self.render_with_dom_node(tag = 'DIV', &block)
              render do
                @_vis_render_block = block
                @_data = params.vis_data
                @_options = params.options
                send(tag, ref: method(:_set_dom_node).to_proc)
              end
            end

            def should_component_update?
              false
            end

            after_mount do
              if @_dom_node && @_vis_render_block
                @_vis_render_block.call(@_dom_node, @_data, @_options)
              end
            end

            before_receive_props do |new_props|
              changed = false
              if new_props[:vis_data] != @_data
                @_data = new_props[:vis_data]
                changed = true
              end
              if new_props[:options] != @_options
                @_options = new_props[:options]
                changed = true
              end
              if changed && @_dom_node && @_vis_render_block
                @_vis_render_block.call(@_dom_node, @_data, @_options)
              end
            end
          end
        end
      end
    end
  end
end