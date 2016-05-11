module ReactiveRecord

  class SyncWrapper

    def initialize(model)
      @model = model
    end

    def where(opts = {})
      opts.each do |attr, value|
        return false unless @model.send(attr) == value
      end
      true
    end

  end

end
