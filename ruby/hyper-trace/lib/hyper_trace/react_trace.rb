
module React
  module Component
    module ClassMethods
      def hypertrace_exclusions
        @@hypertrace_exclusions ||=
          Tags::HTML_TAGS +
          Tags::HTML_TAGS.collect { |t| t.upcase } +
          [
            :_render_wrapper, :params, :find_component, :lookup_const,
            :update_react_js_state, :props_changed?,
            :update_react_js_state2, :set_state, :original_component_did_mount,
            :props, :reactive_record_link_to_enclosing_while_loading_container,
            :reactive_record_link_set_while_loading_container_class,
            :dom_node, :state, :run_callback, :initial_state, :set_state!,
            :set_or_replace_state_or_prop, :original_component_did_update
          ]
      end
    end
    module DslInstanceMethods
      def hypertrace_format_instance(h)
        filtered_vars =
          instance_variables -
          ['@native', '@props_wrapper', '@state_wrapper', '@waiting_on_resources']
        h.format_instance(self, filtered_vars) do
          @props_wrapper.props.each do |param, value|
            val = h.safe_i value
            h.group("params.#{param}: #{val[0..10]}", collapsed: true) do
              puts val
              h.log value
            end
          end if @props_wrapper
          hash = Hash.new(`#{@native}.state`)
          updated_at = hash.delete('***_state_updated_at-***')
          h.group("state last updated at: #{Time.at(updated_at)}") if updated_at
          hash.each do |state, value|
            val = h.safe_i(value)
            h.group("state.#{state}: #{val[0..10]}", collapsed: true) do
              puts val
              h.log value
            end
          end
        end
      end
    end
  end
end
