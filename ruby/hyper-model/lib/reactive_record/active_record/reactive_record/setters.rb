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
        current_value = @attributes[assoc.attribute]
        update_has_many_through_associations assoc, nil, current_value, :remove_member
        update_has_many_through_associations assoc, nil, value, :add_member
        remove_current_inverse_attribute     assoc, nil, current_value
        add_new_inverse_attribute            assoc, nil, value
        update_belongs_to                    attr,  value.itself
      end
    end

    def set_belongs_to_via_has_many(orig, value)
      assoc = orig.inverse
      attr = assoc.attribute
      current_value = @attributes[attr]
      update_has_many_through_associations assoc, orig, current_value, :remove_member
      update_has_many_through_associations assoc, orig, value, :add_member
      remove_current_inverse_attribute     assoc, orig, current_value
      add_new_inverse_attribute            assoc, orig, value
      update_belongs_to                    attr,  value.itself
    end

    def sync_has_many(attr)
      set_change_status_and_notify_only attr, @attributes[attr] != @synced_attributes[attr]
    end

    def update_simple_attribute(attr, value)
      debugger if attr.is_a?(Array) && attr.first.is_a?(Array) && attr.first.first.is_a?(Array)

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
      return if @being_destroyed
      empty_before = changed_attributes.empty?
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

    def remove_current_inverse_attribute(association, orig, model)
      return if model.nil?
      inverse_association = association.inverse(model)
      return if inverse_association == orig
      if inverse_association.collection?
        # note we don't have to check if the collection exists, since it must
        # exist as at this ar_instance is already part of it.
        model.attributes[inverse_association.attribute].delete(@ar_instance)
      else
        model.attributes[inverse_association.attribute] = nil
      end
    end

    def add_new_inverse_attribute(association, orig, model)
      return if model.nil?
      inverse_association = association.inverse(model)
      return if inverse_association == orig
      if inverse_association.collection?
        model.backing_record.push_onto_collection(@model, inverse_association, @ar_instance)
      else
        inverse_attr = inverse_association.attribute
        model.attributes[inverse_attr] = @ar_instance
        return if data_loading?
        Hyperstack::Internal::State::Variable.set(model.backing_record, inverse_attr, @ar_instance)
      end
    end

    def push_onto_collection(model, association, ar_instance)
      @attributes[association.attribute] ||= Collection.new(model, @ar_instance, association)
      @attributes[association.attribute]._internal_push ar_instance
    end

    # class Membership < ActiveRecord::Base
    #   belongs_to :uzer
    #   belongs_to :memerable, polymorphic: true
    # end
    #
    # class Project < ActiveRecord::Base
    #   has_many :memberships, as: :memerable, dependent: :destroy
    #   has_many :uzers, through: :memberships
    # end
    #
    # class Group < ActiveRecord::Base
    #   has_many :memberships, as: :memerable, dependent: :destroy
    #   has_many :uzers, through: :memberships
    # end
    #
    # class Uzer < ActiveRecord::Base
    #   has_many :memberships
    #   has_many :groups,   through: :memberships, source: :memerable, source_type: 'Group'
    #   has_many :projects, through: :memberships, source: :memerable, source_type: 'Project'
    # end

    # membership.uzer = some_new_uzer (i.e. through association is changing)
    # means membership.some_new_uzer.(groups OR projects) << uzer.memberable (depending on type of memberable)
    # and we have to remove the current value of the source association (memerable) from the current uzer group or project
    # and we have to then find any inverse has_many_through association (i.e. group or projects.uzers) and delete the
    # current value from those collections and push the new value on

    def update_has_many_through_associations(assoc, orig, value, method)
      return if value.nil?
      assoc.through_associations(value).each do |ta|
        next if orig == ta
        source_value = @attributes[ta.source]
        # skip if source value is nil or if type of the association does not match type of source
        next unless source_value.class.to_s == ta.source_type
        ta.send method, source_value, value
        ta.source_associations(source_value).each do |sa|
          sa.send method, value, source_value
        end
      end
    end

    # def remove_src_assoc(sa, source_value, current_value)
    #   source_inverse_collection = source_value.attributes[sa.attribute]
    #   source_inverse_collection.delete(current_value) if source_inverse_collection
    # end
    #
    # def add_src_assoc(sa, source_value, new_value)
    #   source_value.attributes[sa.attribute] ||= Collection.new(sa.owner_class, source_value, sa)
    #   source_value.attributes[sa.attribute] << new_value
    # end

  end
end
