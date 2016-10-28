# collection related patches
module ReactiveRecord
  # The base collection class works with relationships
  # methods for scoped collections
  module ScopedCollection
    [:filter?, :collector?, :joins_with?, :related_records_for].each do |method|
      define_method(method) { |*args| @scope_description.send method, *args }
    end

    def set_pre_sync_related_records(related_records, _record = nil)
      @pre_sync_related_records = nil
      ReactiveRecord::Base.catch_db_requests do
        @pre_sync_related_records = filter_records(related_records)
        live_scopes.each do |scope|
          scope.set_pre_sync_related_records(@pre_sync_related_records)
        end
      end if filter?
    end

    def sync_scopes(related_records, record, filtering = true)
      filtering =
        @pre_sync_related_records && filtering &&
        ReactiveRecord::Base.catch_db_requests do
          related_records = update_collection(related_records)
        end
      reload_from_db if !filtering && joins_with?(record)
      live_scopes.each { |scope| scope.sync_scopes(related_records, record, filtering) }
    ensure
      @pre_sync_related_records = nil
    end

    def update_collection(related_records)
      if collector?
        update_collector_scope(related_records)
      else
        related_records = filter_records(related_records)
        update_filter_scope(@pre_sync_related_records, related_records)
      end
    end

    def update_collector_scope(related_records)
      current = Set.new([*@collection])
      (related_records - @pre_sync_related_records).each { |r| current << r }
      (@pre_sync_related_records - related_records).each { |r| current.delete(r) }
      replace(filter_records(current))
      Set.new([*@collection])
    end

    def update_filter_scope(before, after)
      if (collection || !@count.nil?) && before != after
        if collection
          (after - before).each { |r| push r }
          (before - after).each { |r| delete r }
        else
          @count += (after - before).count
          @count -= (before - after).count
          notify_of_change self
        end
      end
      after
    end
  end

  module UnscopedCollection
    def set_pre_sync_related_records(related_records, _record = nil)
      @pre_sync_related_records = related_records
      live_scopes.each { |scope| scope.set_pre_sync_related_records(@pre_sync_related_records) }
    end

    def sync_scopes(related_records, record, filtering = true)
      live_scopes.each { |scope| scope.sync_scopes(related_records, record, filtering) }
    ensure
      @pre_sync_related_records = nil
    end
  end

  class Collection
    attr_reader   :vector
    attr_writer   :scope_description
    attr_writer   :parent
    attr_reader   :pre_sync_related_records

    def to_s
      "<Coll-#{object_id} - #{vector}>"
    end


    class << self
      def sync_scopes(broadcast)
        # record_with_current_values will return nil if data between
        # the broadcast record and the value on the client is out of sync
        # not running set_pre_sync_related_records will cause sync scopes
        # to refresh all related scopes
        React::State.bulk_update do
          record = broadcast.record_with_current_values
          apply_to_all_collections(
            :set_pre_sync_related_records,
            record, broadcast.new?
          ) if record
          record = broadcast.record_with_new_values
          apply_to_all_collections(
            :sync_scopes,
            record, record.destroyed?
          )
          record.backing_record.sync_unscoped_collection! if record.destroyed? || broadcast.new?
        end
      end

      def apply_to_all_collections(method, record, dont_gather)
        related_records = Set.new if dont_gather
        Base.outer_scopes.each do |collection|
          unless dont_gather
            related_records = collection.gather_related_records(record)
          end
          collection.send method, related_records, record
        end
      end
    end

    def gather_related_records(record, related_records = Set.new)
      merge_related_records(record, related_records)
      live_scopes.each do |collection|
        collection.gather_related_records(record, related_records)
      end
      related_records
    end

    def merge_related_records(record, related_records)
      if filter? && joins_with?(record)
        related_records.merge(related_records_for(record))
      end
      related_records
    end

    def filter?
      false
    end

    def collector?
      false
    end

    def filter_records(related_records)
      scope_args = @vector.last.is_a?(Array) ? @vector.last[1..-1] : []
      @scope_description.filter_records(related_records, scope_args)
    end

    def live_scopes
      @live_scopes ||= Set.new
    end

    def set_pre_sync_related_records(related_records, _record = nil)
      @pre_sync_related_records = related_records.intersection([*@collection])
      live_scopes.each { |scope| scope.set_pre_sync_related_records(@pre_sync_related_records) }
    end

    def sync_scopes(related_records, record, filtering = true)
      related_records = related_records.intersection([*@collection])
      live_scopes.each { |scope| scope.sync_scopes(related_records, record, filtering) }
    ensure
      @pre_sync_related_records = nil
    end

    def apply_scope(name, *vector)
      build_child_scope(ScopeDescription.all[@target_klass][name], *name, *vector)
    end

    def child_scopes
      @child_scopes ||= {}
    end

    def build_child_scope(scope_description, *scope_vector)
      child_scopes[scope_vector] ||= begin
        new_vector = @vector
        new_vector += [scope_vector] unless scope_vector.empty?
        child_scope = Collection.new(@target_klass, nil, nil, *new_vector)
        child_scope.scope_description = scope_description
        child_scope.parent = self
        child_scope.extend ScopedCollection
        child_scope
      end
    end

    def link_to_parent
      return if @linked
      @linked = true
      if @parent
        @parent.link_child self
        sync_collection_with_parent unless collection
      else
        ReactiveRecord::Base.add_to_outer_scopes self
      end
      all if collector? # force fetch all so the collector can do its job
    end

    def link_child(child)
      live_scopes << child
      link_to_parent
    end

    def sync_collection_with_parent
      if @parent.collection
        if @parent.collection.empty?
          @collection = []
        elsif filter?
          @collection = filter_records(@parent.collection)
        end
      elsif @parent.count.zero?
        @count = 0
      end
    end

    def reload_from_db(force = nil)
      if force || React::State.has_observers?(self, :collection)
        @out_of_date = false
        ReactiveRecord::Base.load_from_db(nil, *@vector, '*all') if @collection
        ReactiveRecord::Base.load_from_db(nil, *@vector, '*count')
      else
        @out_of_date = true
      end
      self
    end

    def observed
      return if @observing || ReactiveRecord::Base.data_loading?
      begin
        @observing = true
        link_to_parent
        reload_from_db(true) if @out_of_date
        React::State.get_state(self, :collection)
      ensure
        @observing = false
      end
    end

    alias pre_synchromesh_instance_variable_set instance_variable_set

    def instance_variable_set(var, val)
      if var == :@count && !ReactiveRecord::WhileLoading.has_observers?# && !ReactiveRecord::Base.data_loading? # !ReactiveRecord::WhileLoading.has_observers?
        React::State.set_state(self, :collection, collection, true)
      end
      pre_synchromesh_instance_variable_set var, val
    end

    def collect(*args, &block)
      all.collect(*args, &block)
    end

    def each_known_child
      [*collection, *client_pushes].each { |i| yield i }
    end


    alias_method :force_push, '<<'

    def push(item)
      if collection
        self.force_push item
      else
        unsaved_children << item
        @owner.backing_record.update_attribute(@association.attribute) if @owner && @association
        if !@count.nil?
          @count += item.destroyed? ? -1 : 1
          notify_of_change self
        end
      end
      self
    end

    alias_method '<<', :push

    def sort!(*args, &block)
      replace(sort(*args, &block))
    end

    alias pre_synchromesh_replace replace

    def replace(new_array)
      unsaved_children.clear
      new_array = new_array.to_a
      return self if new_array == @collection
      Base.load_data { pre_synchromesh_replace(new_array) }
      notify_of_change new_array
    end

    def delete(item)
      unsaved_children.delete(item)
      notify_of_change(
        if @owner && @association && (inverse_of = @association.inverse_of)
          if (backing_record = item.backing_record) && backing_record.attributes[inverse_of] == @owner
            # the if prevents double update if delete is being called from << (see << above)
            backing_record.update_attribute(inverse_of, nil)
          end
          # forces a check if association contents have changed from synced values
          delete_internal(item) { @owner.backing_record.update_attribute(@association.attribute) }
        else
          delete_internal(item)
        end
      )
    end

    def delete_internal(item)
      if collection
        all.delete(item)
      elsif !@count.nil?
        @count -= 1
      end
      yield item if block_given?
      item
    end
  end
end
