module ReactiveRecord
  # inspection_details is used by client side ActiveRecord::Base
  # runs down the possible states of a backing record and returns
  # the appropriate string.  The order of execution is important!
  module BackingRecordInspector
    def inspection_details
      return error_details    unless errors.empty?
      return new_details      if new?
      return destroyed_details if destroyed
      return loading_details  unless @attributes.key? primary_key
      return dirty_details    unless changed_attributes.empty?
      "[loaded id: #{id}]"
    end

    def error_details
      id_str = "id: #{id} " unless new?
      "[errors #{id_str}#{errors.messages}]"
    end

    def new_details
      "[new #{attributes.select { |attr| column_type(attr) }}]"
    end

    def destroyed_details
      "[destroyed id: #{id}]"
    end

    def loading_details
      "[loading #{vector}]"
    end

    def dirty_details
      "[changed id: #{id} #{changes}]"
    end
  end
end
