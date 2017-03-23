module React
  class RenderingContext
    def self.remove_nodes_from_args(args)
      return unless args[0] && args[0].is_a?(Hash)

      args[0].values do |value|
        js_value = `#{value}['$is_a?']`
        value.as_node if js_value && value.is_a?(Element)
      end
    end
  end
end
