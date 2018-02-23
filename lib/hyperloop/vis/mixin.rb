require 'react/component'

module Hyperloop
  module Vis
    module Mixin
      def self.included(base)
        base.include(Hyperloop::Component::Mixin)
        base.class_eval do
          param data: nil

          def _set_dom_node(dom_node)
            @_dom_node = dom_node
          end

          def data
            @_data
          end
          
          def self.render_with_dom_node(tag = 'DIV', &block)
            render do
              @_vis_render_block = block
              @_data = params.data
              send(tag, ref: method(:_set_dom_node).to_proc)
            end
          end

          def should_component_update?
            false
          end

          after_mount do
            if @_dom_node && @_vis_render_block
              @_vis_render_block.call(@_dom_node, @_data)
            end
          end

          before_receive_props do |new_props|
            if new_props[:data] != @_data
              @_data = new_props[:data] 
              if @_dom_node && @_vis_render_block
                @_vis_render_block.call(@_dom_node, @_data)
              end
            end
          end
        end
      end
      
    end
  end
end