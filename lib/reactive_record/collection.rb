# collection related patches
module ReactiveRecord
  # The base collection class works with relationships
  # methods for scoped collections
  module ScopedCollection
    [:filter?, :collector?, :joins_with?, :filter_records, :related_records_for].each do |method|
      define_method(method) { |*args| @scope_description.send method, *args }
    end

    def set_pre_sync_related_records(related_records, _record = nil)
      puts "scoped: #{self}.set_pre_sync_related_records([#{related_records.to_a}]) filter? #{filter?}"

      ReactiveRecord::Base.catch_db_requests do
        @pre_sync_related_records = filter_records(related_records)
        live_scopes.each do |scope|
          scope.set_pre_sync_related_records(@pre_sync_related_records)
        end
      end if filter?
      puts "scoped: #{self} @pre_sync_related_records: [#{@pre_sync_related_records.to_a}]"
    end

    def sync_scopes(related_records, record, filtering = true)
      puts "going to sync#{self}... filtering: #{!!filtering} presync_related: [#{@pre_sync_related_records.to_a}], related_records: #{related_records.to_a}"
      filtering =
        @pre_sync_related_records && filtering &&
        ReactiveRecord::Base.catch_db_requests do
          puts "about the update_collection: [#{related_records.to_a}]"
          related_records = update_collection(related_records)
        end.tap { |x| puts "returned #{x} from update_collection" }
      if !filtering && joins_with?(record)
        puts "reloading! filtering = #{!!filtering} joined = #{!!joins_with?(record)}"
        reload_from_db
      end
      live_scopes.each { |scope| scope.sync_scopes(related_records, record, filtering) }
    ensure
      @pre_sync_related_records = nil
    end

    def update_collection(related_records)
      puts "updating_collection([#{related_records.to_a}])"
      if collector?
        replace(filter_records(all + related_records.to_a))
        related_records.intersection([*@collection])
      else
        add_filtered_records_to_collection(
          @pre_sync_related_records, filter_records(related_records)
        )
      end
    end

    def add_filtered_records_to_collection(before, after)
      puts "add_filtered_records_to_collection([#{before.to_a}], [#{after.to_a}])"
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

    class << self

      def sync_scopes(broadcast)
        # record_with_current_values will return nil if data between
        # the broadcast record and the value on the client is out of sync
        # not running set_pre_sync_related_records will cause sync scopes
        # to refresh all related scopes
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

      def apply_to_all_collections(method, record, dont_gather)
        puts "apply_to_all_collections(#{method}, #{record}, #{!!dont_gather})"
        related_records = Set.new if dont_gather
        puts "all_class_scopes: #{Base.all_class_scopes.count}"
        Base.all_class_scopes.each do |collection|
          unless dont_gather
            related_records = collection.gather_related_records(record)
          end
          collection.send method, related_records, record
        end
      end
    end

    def gather_related_records(record, related_records = Set.new)
      puts "gathering related records(#{record}, [#{related_records.to_a}])"
      merge_related_records(record, related_records)
      live_scopes.each do |collection|
        collection.gather_related_records(record, related_records)
      end
      related_records.tap { |x| puts "related_records = [#{related_records.to_a}]"}
    end

    def merge_related_records(record, related_records)
      if filter? && joins_with?(record)
        related_records.merge(related_records_for(record))
      end
      related_records.tap { |x| puts "merge_related_records returns [#{x.to_a}]"}
    end

    def filter?
      false
    end

    def collector?
      false
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
        child_scope = Collection.new(@target_klass, @owner, @association, *new_vector)
        child_scope.scope_description = scope_description
        #ReactiveRecord::Base.class_scopes(@target_klass)[self] ||= self if base_scope?
        child_scope.parent = self
        child_scope.extend ScopedCollection
        #child_scope.all if child_scope.collector? # force fetch all so the collector can do its job
        puts "built new child scope.  parent = #{self} child = #{child_scope} scope = #{scope_description} vector = #{scope_vector}"
        child_scope
      end
    end

    def link_to_parent
      return if @linked
      @linked = true
      all if collector? # force fetch all so the collector can do its job
      if @parent
        @parent.link_child self
      else
        ReactiveRecord::Base.class_scopes(@target_klass)[self] ||= self
      end
    end

    def link_child(child)
      live_scopes << child
      link_to_parent
    end

    def reload_from_db(force = nil)
      puts "gotta reload from db!"
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
      return if @observing
      begin
        @observing = true
        link_to_parent
        reload_from_db(true) if @out_of_date
        puts "*******observing #{self} data_loading? #{ReactiveRecord::Base.data_loading?}"
        React::State.get_state(self, :collection) unless ReactiveRecord::Base.data_loading?
      ensure
        @observing = false
      end
    end

    alias pre_synchromesh_instance_variable_set instance_variable_set

    def instance_variable_set(var, val)
      if var == :@count && !ReactiveRecord::WhileLoading.has_observers?
        React::State.set_state(self, :collection, collection, true)
      end
      pre_synchromesh_instance_variable_set var, val
    end

    alias_method :pre_synchromesh_push, '<<'

    def push(item)
      puts "***************** #{self}.push(#{item})"
      if collection
        puts "has a collection using old method"
        pre_synchromesh_push item
      elsif !@count.nil?
        @count += item.destroyed? ? -1 : 1
        puts "*****notify_of_change #{self}"
        notify_of_change self
      else
        puts "***************** no collection ignoring ********************"
      end
      puts "all done"
      self
    end

    alias_method '<<', :push
    #alias_method :push, '<<'

    def sort!(*args, &block)
      replace(sort(*args, &block))
    end

    alias pre_synchromesh_replace replace

    def replace(new_array)
      puts "************#{self}.replace([#{new_array}])"
      new_array = new_array.to_a
      return self if new_array == @collection
      Base.load_data { pre_synchromesh_replace(new_array) }
      notify_of_change new_array
    end

    def delete(item)
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
