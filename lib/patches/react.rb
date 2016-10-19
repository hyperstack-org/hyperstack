module React
  class RenderingContext
    def self.remove_nodes_from_args(args)
      args[0].each do |key, value|
        value.as_node if `value['$is_a?']` && value.is_a?(Element)
      end if args[0] && args[0].is_a?(Hash)
    end
  end
end
