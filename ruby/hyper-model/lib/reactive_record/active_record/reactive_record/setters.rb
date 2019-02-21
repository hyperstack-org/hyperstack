module ReactiveRecord
  module Setters
    def set_attr_value(attr, raw_value)
      set_common(attr, raw_value) { |value| update_simple_attribute(attr, value) }
    end

    def set_ar_aggregate(aggr, raw_value)
      set_common(aggr.attribute, raw_value) do |value, attr|
        @attributes[attr] ||= aggr.klass.new if new?
        abr = @attributes[attr].backing_record
        abr.virgin = false
        map = value.attributes if value
        aggr.mapped_attributes.each do |mapped_attr|
          abr.update_aggregate_attribute mapped_attr, map && map[mapped_attr]
        end
        return @attributes[attr]
      end
    end

    def set_non_ar_aggregate(aggregation, raw_value)
      set_common(aggregation.attribute, raw_value) do |value, attr|
        if data_loading?
          @synced_attributes[attr] = aggregation.deserialize(aggregation.serialize(value))
        else
          changed = !@synced_attributes.key?(attr) || @synced_attributes[attr] != value
        end
        set_attribute_change_status_and_notify attr, changed, value
      end
    end

    def set_has_many(assoc, raw_value)
      puts "********* set_has_many called **********"
      set_common(assoc.attribute, raw_value) do |value, attr|
        # create a new collection to hold value, shove it in, and return the new collection
        # the replace method will take care of updating the inverse belongs_to links as
        # the collection is overwritten
        collection = Collection.new(assoc.klass, @ar_instance, assoc)
        collection.replace(value || [])
        @synced_attributes[attr] = value if data_loading?
        set_attribute_change_status_and_notify attr, value != @synced_attributes[attr], collection
        return collection
      end
    end

    def set_belongs_to(assoc, raw_value)
      set_common(assoc.attribute, raw_value) do |value, attr|
        update_has_many_through_associations assoc, value
        update_current_inverse_attribute     assoc, @attributes[assoc.attribute]
        update_new_inverse_attribute         assoc, value
        update_belongs_to                    attr,  value.itself
      end
    end

    def sync_has_many(attr)
      set_change_status_and_notify_only attr, @attributes[attr] != @synced_attributes[attr]
    end

    def update_simple_attribute(attr, value)
      if data_loading?
        @synced_attributes[attr] = value
      else
        changed = !@synced_attributes.key?(attr) || @synced_attributes[attr] != value
      end
      set_attribute_change_status_and_notify attr, changed, value
    end

    alias update_belongs_to update_simple_attribute
    alias update_aggregate_attribute update_simple_attribute

    private

    def set_common(attr, value)
      value = convert(attr, value)
      @virgin = false unless data_loading?
      if !@destroyed && (
           !@attributes.key?(attr) ||
           @attributes[attr].is_a?(Base::DummyValue) ||
           @attributes[attr] != value)
        yield value, attr
      end
      value
    end

    def set_attribute_change_status_and_notify(attr, changed, new_value)
      if @virgin
        @attributes[attr] = new_value
      else
        change_status_and_notify_helper(attr, changed) do |had_key, current_value|
          @attributes[attr] = new_value
          if !data_loading? ||
             (on_opal_client? && had_key && current_value.loaded? && current_value != new_value)
            Hyperstack::Internal::State::Variable.set(self, attr, new_value, data_loading?)
          end
        end
      end
    end

    def set_change_status_and_notify_only(attr, changed)
      return if @virgin
      change_status_and_notify_helper(attr, changed) do
        Hyperstack::Internal::State::Variable.set(self, attr, nil) unless data_loading?
      end
    end

    def change_status_and_notify_helper(attr, changed)
      empty_before = changed_attributes.empty?
      # TODO: confirm this works:
      # || data_loading? added so that model.new can be wrapped in a ReactiveRecord.load_data
      if !changed || data_loading?
        changed_attributes.delete(attr)
      elsif !changed_attributes.include?(attr)
        changed_attributes << attr
      end
      yield @attributes.key?(attr), @attributes[attr]
      return unless empty_before != changed_attributes.empty?
      if on_opal_client? && !data_loading?
        Hyperstack::Internal::State::Variable.set(self, '!CHANGED!', !changed_attributes.empty?, true)
      end
      return unless aggregate_owner
      aggregate_owner.set_change_status_and_notify_only(
        attr, !@attributes[attr].backing_record.changed_attributes.empty?
      )
    end

    # when updating the inverse attribute of a belongs_to that is itself a belongs_to
    # (i.e. 1-1 relationship) we clear the existing inverse value and then
    # write the current record to the new value

    # when updating an inverse attribute of a belongs_to that is a has_many (i.e. a collection)
    # we need to first remove the current associated value (if non-nil), then add the new
    # value to the collection.  If the inverse collection is not yet initialized we do it here.

    # the above is split into three methods, because the  inverse of apolymorphic belongs to may
    # change from has_one to has_many.  So we first deal with the current value, then
    # update the new value which uses the push_onto_collection helper

    def update_current_inverse_attribute(association, model)
      return if model.nil?
      inverse_association = association.inverse(model)
      if inverse_association.collection?
        # note we don't have to check if the collection exists, since it must
        # exist as at this ar_instance is already part of it.
        model.attributes[inverse_association.attribute].delete(@ar_instance)
      else
        model.attributes[inverse_association.attribute] = nil
      end
    end

    def update_new_inverse_attribute(association, model)
      return if model.nil?
      inverse_association = association.inverse(model)
      if inverse_association.collection?
        model.backing_record.push_onto_collection(@model, inverse_association, @ar_instance)
      else
        inverse_attr = inverse_association.attribute
        value.attributes[inverse_attr] = @ar_instance
        return if data_loading?
        Hyperstack::Internal::State::Variable.set(model.backing_record, inverse_attr, @ar_instance)
      end
    end

    def push_onto_collection(model, association, ar_instance)
      @attributes[association.attribute] ||= Collection.new(model, @ar_instance, association)
      @attributes[association.attribute] << ar_instance
    end

    def update_has_many_through_associations(assoc, value)
      # note that through and source_associations returns an empty set of
      # the provided ar_instance does not belong to a has_many_through association
      assoc.through_associations(@ar_instance)
           .each { |ta| update_through_association(assoc, ta, value) }
      assoc.source_associations(@ar_instance)
           .each { |sa| update_source_association(assoc, sa, value) }
    end

    def update_through_association(assoc, ta, new_belongs_to_value)
      # appointment.doctor = doctor_new_value (i.e. through association is changing)
      # means appointment.doctor_new_value.patients << appointment.patient
      # and we have to appointment.doctor_current_value.patients.delete(appointment.patient)
      source_value = @attributes[ta.source]
      current_belongs_to_value = @attributes[assoc.attribute]
      return unless source_value.class.to_s == ta.source_type
      unless current_belongs_to_value.nil? || current_belongs_to_value.attributes[ta.attribute].nil?
        current_belongs_to_value.attributes[ta.attribute].delete(source_value)
      end
      return unless new_belongs_to_value
      new_belongs_to_value.attributes[ta.attribute] ||= Collection.new(assoc.owner_class, new_belongs_to_value, ta)
      new_belongs_to_value.attributes[ta.attribute] << source_value
    end

    def update_source_association(assoc, sa, new_source_value)
      # appointment.patient = patient_value (i.e. source is changing)
      # means appointment.doctor.patients.delete(appointment.patient)
      # means appointment.doctor.patients << patient_value
      belongs_to_value = @attributes[assoc.attribute]
      current_source_value = @attributes[sa.source]
      return unless belongs_to_value
      unless belongs_to_value.attributes[sa.attribute].nil? || current_source_value.nil?
        belongs_to_value.attributes[sa.attribute].delete(current_source_value)
      end
      return unless new_source_value
      belongs_to_value.attributes[sa.attribute] ||= Collection.new(sa.klass(new_source_value), belongs_to_value, sa)
      belongs_to_value.attributes[sa.attribute] << new_source_value
    end
  end
end
