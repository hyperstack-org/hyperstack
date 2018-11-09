
module Hyperstack
  module Internal
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
              :set_or_replace_state_or_prop, :original_component_did_update, :observing,
              :update_objects_to_observe, :remove, :set, :mutations
            ]
        end
      end
      module InstanceMethods
        def hypertrace_format_instance(h)
          filtered_vars = instance_variables.reject { |var| var =~ /@__hyperstack_/ }
          filtered_vars = filtered_vars.select { |var| var =~ /@[A-Z]/ } +
                          filtered_vars.reject { |var| var =~ /@[A-Z]/ }
          h.format_instance(self, filtered_vars) do
            updated_at = `#{@__hyperstack_component_native}.state['***_state_updated_at-***']`
            h.group("state last updated at: #{Time.at(updated_at)}") if updated_at
          end
        end
      end
    end
  end
end
