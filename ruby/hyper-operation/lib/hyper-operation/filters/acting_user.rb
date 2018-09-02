module Hyperloop
  class ActingUser
    @default_options = {
      :nils => false   # true allows an explicit nil to be valid. Overrides any other options
    }

    def filter(data)

      # Handle nil case
      if data.nil?
        return [nil, nil] if options[:nils]
        return [nil, :nils]
      end

      # otherwise, we win.
      return [data, nil]
    end
  end
end
