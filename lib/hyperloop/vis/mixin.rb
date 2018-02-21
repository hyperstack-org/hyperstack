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

          def self.before_unmount_with_selection(&block)
            before_unmount do
              if @_dom_node && block
                selection = ::D3.select(@_dom_node)
                block.call(selection, @_data)
              end
            end
          end

          def self.render_with_selection(tag = 'SVG', &block)
            render do
              if block
                @_d3_render_block = block
              else
                @_d3_render_block = proc { |selection, data| selection.text("Please supply a block for render_with_selection")}
              end
              @_data = params.data
              send(tag, ref: method(:_set_dom_node).to_proc)
            end
          end

          def should_component_update?
            false
          end

          after_mount do
            if @_dom_node && @_d3_render_block
              selection = ::D3.select(@_dom_node)
              @_d3_render_block.call(selection, @_data)
            end
          end

          before_receive_props do |new_props|
            if new_props[:data] != @_data
              @_data = new_props[:data] 
              if @_dom_node && @_d3_render_block
                selection = ::D3.select(@_dom_node)
                @_d3_render_block.call(selection, @_data)
              end
            end
          end
        end
      end

    end
  end
end