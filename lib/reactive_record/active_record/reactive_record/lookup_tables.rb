module ReactiveRecord
  module LookupTables
    def initialize_lookup_tables
      @records = Hash.new { |hash, key| hash[key] = [] }
      @records_by_id = `{}`
      @records_by_vector = `{}`
      @records_by_object_id = `{}`
      @class_scopes = Hash.new { |hash, key| hash[key] = {} }
      @waiting_for_save = Hash.new { |hash, key| hash[key] = [] }
    end

    def class_scopes(model)
      @class_scopes[model.base_class]
    end

    def waiting_for_save(model)
      @waiting_for_save[model]
    end

    def wait_for_save(model, &block)
      @waiting_for_save[model] << block
    end

    def clear_waiting_for_save(model)
      @waiting_for_save[model] = []
    end

    def lookup_by_object_id(object_id)
      `#{@records_by_object_id}[#{object_id}]`.ar_instance
    end

    def set_object_id_lookup(record)
      `#{@records_by_object_id}[#{record.object_id}] = #{record}`
    end

    def lookup_by_id(*args) # model and id
      `#{@records_by_id}[#{args}]` || nil
    end

    def set_id_lookup(record)
      `#{@records_by_id}[#{[record.model, record.id]}] = #{record}`
    end

    def lookup_by_vector(vector)
      `#{@records_by_vector}[#{vector}]` || nil
    end

    def set_vector_lookup(record, vector)
      record.vector = vector
      `delete #{@records_by_vector}[#{record.vector}]`
      `#{@records_by_vector}[#{vector}] = record`
    end
  end
end
