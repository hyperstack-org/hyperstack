module ReactiveRecord
  # inspection_details is used by client side ActiveRecord::Base
  # runs down the possible states of a backing record and returns
  # the appropriate string.  The order of execution is important!
  module BackingRecordInspector
    def inspection_details
      return error_details     unless errors.empty?
      return new_details       if new?
      return destroyed_details if destroyed
      return loading_details   unless @attributes.key? primary_key
      return dirty_details     unless changed_attributes.empty?
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
      "[loading #{pretty_vector}]"
    end

    def dirty_details
      "[changed id: #{id} #{changes}]"
    end

    def pretty_vector
      v = []
      i = 0
      while i < vector.length
        if vector[i] == 'all' && vector[i + 1].is_a?(Array) &&
           vector[i + 1][0] == '___hyperstack_internal_scoped_find_by' &&
           vector[i + 2] == '*0'
          v << ['find_by', vector[i + 1][1]]
          i += 3
        else
          v << vector[i]
          i += 1
        end
      end
      v
    end
  end
end
