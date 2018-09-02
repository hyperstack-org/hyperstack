module Mutations
  class OutboundFilter < AdditionalFilter
    @default_options = {}

    def filter(data)
      return [data, :outbound]
    end
  end
end
