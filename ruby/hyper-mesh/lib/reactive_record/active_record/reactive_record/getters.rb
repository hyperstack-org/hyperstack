module ReactiveRecord
  # creates getters for various method types
  # TODO replace sync_attribute calls with direct logic
  module Getters
    def get_belongs_to(assoc, reload = nil)
      getter_common(assoc.attribute, reload) do |has_key, attr|
        return if new?
        value = Base.fetch_from_db([@model, [:find, id], attr, @model.primary_key]) if id.present?
        value = find_association(assoc, value)
        sync_ignore_dummy attr, value, has_key
      end&.cast_to_current_sti_type
    end

    def get_has_many(assoc, reload = nil)
      getter_common(assoc.attribute, reload) do |_has_key, attr|
        if new?
          @attributes[attr] = Collection.new(assoc.klass, @ar_instance, assoc)
        else
          sync_attribute attr, Collection.new(assoc.klass, @ar_instance, assoc, *vector, attr)
        end
      end
    end

    def get_attr_value(attr, reload = nil)
      non_relationship_getter_common(attr, reload) do
        sync_attribute attr, convert(attr, model.columns_hash[attr][:default])
      end
    end

    def get_primary_key_value
      non_relationship_getter_common(model.primary_key, false)
    end

    def get_server_method(attr, reload = nil)
      non_relationship_getter_common(attr, reload) do |has_key|
        sync_ignore_dummy attr, Base.load_from_db(self, *(vector ? vector : [nil]), attr), has_key
      end
    end

    def get_ar_aggregate(aggr, reload = nil)
      getter_common(aggr.attribute, reload) do |has_key, attr|
        if new?
          @attributes[attr] = aggr.klass.new.backing_record.link_aggregate(attr, self)
        else
          sync_ignore_dummy attr, new_from_vector(aggr.klass, self, *vector, attr), has_key
        end
      end
    end

    def get_non_ar_aggregate(attr, reload = nil)
      non_relationship_getter_common(attr, reload)
    end

    private

    def virtual_fetch_on_server_warning(attr)
      log(
        "Warning fetching virtual attributes (#{model.name}.#{attr}) during prerendering "\
        'on a changed or new model is not implemented.',
        :warning
      )
    end

    def sync_ignore_dummy(attr, value, has_key)
      # ignore the value if its a Dummy value and there is already a value present
      # this is used to implement reloading.  During the reload while we are waiting we
      # want the current attribute (if its present) to not change.  Once the fetch
      # is complete the fetch process will reload the attribute
      value = @attributes[attr] if has_key && value.is_a?(Base::DummyValue)
      sync_attribute(attr, value)
    end

    def non_relationship_getter_common(attr, reload, &block)
      getter_common(attr, reload) do |has_key|
        if new?
          yield has_key if block
        elsif on_opal_client?
          sync_ignore_dummy attr, Base.load_from_db(self, *(vector ? vector : [nil]), attr), has_key
        elsif id.present?
          sync_attribute attr, Base.fetch_from_db([@model, [:find, id], attr])
        else
          sync_attribute attr, Base.fetch_from_db([*vector, attr])
        end
      end
    end

    def getter_common(attribute, reload)
      @virgin = false unless data_loading?
      return if @destroyed
      if @attributes.key? attribute
        current_value = @attributes[attribute]
        current_value.notify if current_value.is_a? Base::DummyValue
        if reload
          virtual_fetch_on_server_warning(attribute) if on_opal_server? && changed?
          yield true, attribute
        else
          current_value
        end
      else
        virtual_fetch_on_server_warning(attribute) if on_opal_server? && changed?
        yield false, attribute
      end.tap { |value| React::State.get_state(self, attribute) unless data_loading? }
    end

    def find_association(association, id)
      inverse_of = association.inverse_of
      instance = if id
        find(association.klass, association.klass.primary_key => id)
      else
        new_from_vector(association.klass, nil, *vector, association.attribute)
      end
      instance_backing_record_attributes = instance.attributes
      inverse_association = association.klass.reflect_on_association(inverse_of)
      if inverse_association.collection?
        instance_backing_record_attributes[inverse_of] = if id and id != ""
          Collection.new(@model, instance, inverse_association, association.klass, ["find", id], inverse_of)
        else
          Collection.new(@model, instance, inverse_association, *vector, association.attribute, inverse_of)
        end unless instance_backing_record_attributes[inverse_of]
        instance_backing_record_attributes[inverse_of].replace [@ar_instance]
      else
        instance_backing_record_attributes[inverse_of] = @ar_instance
      end unless association.through_association? || instance_backing_record_attributes.key?(inverse_of)
      instance
    end

    def link_aggregate(attr, parent)
      self.aggregate_owner = parent
      self.aggregate_attribute = attr
      @ar_instance
    end
  end
end
