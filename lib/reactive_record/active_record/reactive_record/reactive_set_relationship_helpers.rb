module ReactiveRecord
  # methods to update aggregrations and relations, called from reactive_set!
  class Base
    def update_aggregate(attribute, value)
      # if attribute is an aggregate then
      # match and update all fields in the aggregate from value and return true
      # otherwise return false
      aggregation = @model.reflect_on_aggregation(attribute)
      return false unless aggregation && (aggregation.klass < ActiveRecord::Base)
      if value
        value_attributes = value.backing_record.attributes
        update_mapped_attributes(aggregation) { |attr| value_attributes[attr] }
      else
        update_mapped_attributes(aggregation) { nil }
      end
      true
    end

    def update_mapped_attributes(aggregation)
      # insure the aggregate attr is initialized, clear the virt flag, the caller
      # will yield each of the matching attribute values
      attr = aggregation.attribute
      attributes[attr] ||= aggregation.klass.new if new?
      aggregate_record = attributes[attr]
      raise 'uninitialized aggregate attribute - should never happen' unless aggregate_record
      aggregate_backing_record = aggregate_record.backing_record
      aggregate_backing_record.virgin = false
      aggregation.mapped_attributes.each do |mapped_attribute|
        aggregate_backing_record.update_attribute(mapped_attribute, yield(mapped_attribute))
      end
    end

    def update_relationships(attr, value)
      # update the inverse relationship, and any through relationships
      # return either the value, or in the case of updating a collection
      # return the new collection after value is overwritten into it.
      association = @model.reflect_on_association(attr)
      return value unless association
      if association.collection?
        overwrite_has_many_collection(association, value)
      else
        update_belongs_to_association(association, value)
        value
      end
    end

    def overwrite_has_many_collection(association, value)
      # create a new collection to hold value, shove it in, and return the new collection
      # the replace method will take care of updating the inverse belongs_to links as
      # the collection is overwritten
      Collection.new(association.klass, @ar_instance, association).tap do |collection|
        collection.replace(value || [])
      end
    end

    def update_belongs_to_association(association, value)
      # either update update the inverse has_many collection or individual belongs_to
      # inverse values
      if association.inverse.collection?
        update_has_many_through_associations(association, value)
        update_inverse_collections(association, value)
      else
        update_inverse_attribute(association, value)
      end
    end

    def update_inverse_attribute(association, value)
      # when updating the inverse attribute of a belongs_to that is itself a belongs_to
      # (i.e. 1-1 relationship) we clear the existing inverse value and then
      # write the current record to the new value
      current_value = attributes[association.attribute]
      inverse_attr = association.inverse.attribute
      current_value.attributes[inverse_attr] = nil unless current_value.nil?
      return if value.nil?
      value.attributes[inverse_attr] = @ar_instance
      return if data_loading?
      React::State.set_state(value.backing_record, inverse_attr, @ar_instance)
    end

    def update_inverse_collections(association, value)
      # when updating an inverse attribute of a belongs_to that is a has_many (i.e. a collection)
      # we need to first remove the current associated value (if non-nil), then add the new
      # value to the collection.  If the inverse collection is not yet initialized we do it here.
      current_value = attributes[association.attribute]
      inverse_attr = association.inverse.attribute
      if value.nil?
        current_value.attributes[inverse_attr].delete(@ar_instance) unless current_value.nil?
      else
        value.backing_record.push_onto_collection(association.inverse, @ar_instance)
      end
    end

    def push_onto_collection(association, ar_instance)
      attributes[association.attribute] ||= Collection.new(@model, @ar_instance, association)
      attributes[association.attribute] << ar_instance
    end

    def update_has_many_through_associations(association, value)
      association.through_associations.each { |ta| update_through_association(ta, value) }
      association.source_associations.each { |sa| update_source_association(sa, value) }
    end

    def update_through_association(ta, new_belongs_to_value)
      # appointment.doctor = doctor_new_value (i.e. through association is changing)
      # means appointment.doctor_new_value.patients << appointment.patient
      # and we have to appointment.doctor_current_value.patients.delete(appointment.patient)
      source_value = attributes[ta.source]
      current_belongs_to_value = attributes[ta.inverse.attribute]
      return unless source_value
      unless current_belongs_to_value.nil? || current_belongs_to_value.attributes[ta.attribute].nil?
        current_belongs_to_value.attributes[ta.attribute].delete(source_value)
      end
      return unless new_belongs_to_value
      new_belongs_to_value.attributes[ta.attribute] ||= Collection.new(ta.klass, new_belongs_to_value, ta)
      new_belongs_to_value.attributes[ta.attribute] << source_value
    end

    def update_source_association(sa, new_source_value)
      # appointment.patient = patient_value (i.e. source is changing)
      # means appointment.doctor.patients.delete(appointment.patient)
      # means appointment.doctor.patients << patient_value
      belongs_to_value = attributes[sa.inverse.attribute]
      current_source_value = attributes[sa.source]
      return unless belongs_to_value
      unless belongs_to_value.attributes[sa.attribute].nil? || current_source_value.nil?
        belongs_to_value.attributes[sa.attribute].delete(current_source_value)
      end
      return unless new_source_value
      belongs_to_value.attributes[sa.attribute] ||= Collection.new(sa.klass, belongs_to_value, sa)
      belongs_to_value.attributes[sa.attribute] << new_source_value
    end
  end
end

    # def reactive_set!(attribute, value)
    #   @virgin = false unless data_loading?
    #   unless @destroyed or (!(attributes[attribute].is_a? DummyValue) and attributes.has_key?(attribute) and attributes[attribute] == value)
    #     if association = @model.reflect_on_association(attribute)
    #       if association.collection?
    #         collection = Collection.new(association.klass, @ar_instance, association)
    #         collection.replace(value || [])
    #         value = collection
    #       else
    #         inverse_of = association.inverse_of
    #         inverse_association = association.klass.reflect_on_association(inverse_of)
    #         if inverse_association.collection?
    #           if value.nil?
    #             attributes[attribute].attributes[inverse_of].delete(@ar_instance) unless attributes[attribute].nil?
    #           elsif value.attributes[inverse_of]
    #             value.attributes[inverse_of] << @ar_instance
    #           else
    #             value.attributes[inverse_of] = Collection.new(@model, value, inverse_association)
    #             # value.attributes[inverse_of].replace [@ar_instance]
    #             # why was the above not just the below???? fixed 10/28/2016
    #             value.attributes[inverse_of] << @ar_instance
    #           end
    #         elsif !value.nil?
    #           attributes[attribute].attributes[inverse_of] = nil unless attributes[attribute].nil?
    #           value.attributes[inverse_of] = @ar_instance
    #           React::State.set_state(value.backing_record, inverse_of, @ar_instance) unless data_loading?
    #         elsif attributes[attribute]
    #           attributes[attribute].attributes[inverse_of] = nil
    #         end
    #       end
    #     elsif aggregation = @model.reflect_on_aggregation(attribute) and (aggregation.klass < ActiveRecord::Base)
    #
    #       if new?
    #         attributes[attribute] ||= aggregation.klass.new
    #       elsif !attributes[attribute]
    #         raise "uninitialized aggregate attribute - should never happen"
    #       end
    #
    #       aggregate_record = attributes[attribute].backing_record
    #       aggregate_record.virgin = false
    #
    #       if value
    #         value_attributes = value.backing_record.attributes
    #         aggregation.mapped_attributes.each { |mapped_attribute| aggregate_record.update_attribute(mapped_attribute, value_attributes[mapped_attribute])}
    #       else
    #         aggregation.mapped_attributes.each { |mapped_attribute| aggregate_record.update_attribute(mapped_attribute, nil) }
    #       end
    #
    #       return attributes[attribute]
    #
    #     end
    #     update_attribute(attribute, value)
    #   end
    #   value
    # end
