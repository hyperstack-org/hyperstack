# Special handling of input tags so they ignore defaultValue (and defaultChecked) values while loading.
# This is accomplished by adding a react 'key prop' that tracks whether the default value is loading.
# When the default value transitions from loading to loaded the key will be updated causing react to
# remount the component with the new default value.
# To handle cases where defaultValue (or defaultChecked) is an expression, a proc (or lambda) can be
# provided for the default value.  The proc will be called, and if it raises the waiting_on_resources
# flag then we know that within that expression there is a value still being loaded, and the react
# key will be set accordingly.

module React
  module Component
    module Tags
      %i[INPUT SELECT TEXTAREA].each do |component|
        remove_method component
        send(:remove_const, component)
        tag = component.downcase
        klass = Class.new(Hyperloop::Component) do
          collect_other_params_as :opts
          render do
            opts = props.dup  # should be opts = params.opts.dup but requires next release candiate of hyper-react
            default_value = opts[:defaultValue] || opts[:defaultChecked]
            if default_value.respond_to? :call
              begin
                saved_waiting_on_resources = React::RenderingContext.waiting_on_resources
                React::RenderingContext.waiting_on_resources = false
                default_value = default_value.call
                opts[:key] = React::RenderingContext.waiting_on_resources
                if opts[:defaultValue]
                  opts[:defaultValue] = default_value
                else
                  opts[:defaultChecked] = default_value
                end
              ensure
                React::RenderingContext.waiting_on_resources = !!saved_waiting_on_resources
              end
            else
              opts[:key] = !!default_value.loading?
            end
            opts[:value] = opts[:value].to_s if opts.key? :value  # this may not be needed
            React::RenderingContext.render(tag, opts) { children.each(&:render) }
          end
        end
        const_set component, klass
      end
    end
  end
end
