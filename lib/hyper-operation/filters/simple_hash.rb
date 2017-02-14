module Mutations
  class SimpleHashFilter < AdditionalFilter
    @default_options = {
      :nils => false   # true allows an explicit nil to be valid. Overrides any other options
    }

    def filter(data)

      # Handle nil case
      if data.nil?
        return [nil, nil] if options[:nils]
        return [nil, :nils]
      end
      
      # Now check if it's empty:
      return [data, :empty] if data == {}

      # If data is a hash, we win.
      return [data, nil] if data.is_a? Hash
    end
  end
end
