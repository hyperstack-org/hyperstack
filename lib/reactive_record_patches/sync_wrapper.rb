module ReactiveRecord
  # SyncWrapper is used to wrap a active-record where method
  # so we can use it on the client.  Currently only handles
  # the most basic where clause in the form where(attribute: value, ...)
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
