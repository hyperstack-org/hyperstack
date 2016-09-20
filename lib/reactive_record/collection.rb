module ReactiveRecord

  class Collection

    attr_reader :vector
    attr_reader :scope_description

    class << self
      def add_scope(klass, name, joins_list, sync_proc)
        scope_descriptions[klass][name] = ScopeDescription.new(name, klass, joins_list, sync_proc)
      end

      def add_scoped_collection(klass, scope, collection)
        puts "add_scoped_collection(#{klass}, #{scope}, #{collection}) returns #{scope_descriptions[klass][scope]}"
        @scoped_collections ||= []
        @scoped_collections << collection
        scope_descriptions[klass][scope]
      end

      def sync_scopes(record)
        return unless @scoped_collections
        @scoped_collections.each do | collection |
          collection.sync_scope(record)
        end
      end

      def scope_descriptions
        @scope_descriptions ||= Hash.new { |hash, key| hash[key] = Hash.new }
      end
    end

    def set_scope(scope)
      @scope_description = self.class.add_scoped_collection(@target_klass, scope, self)
      self
    end

    def apply_scope(scope, *args)
      # The value returned is another ReactiveRecordCollection with the scope added to the vector
      # no additional action is taken
      scope_vector = [scope, *args] if args.count > 0
      @scopes[scope_vector] ||=
        Collection.new(@target_klass, @owner, @association, *@vector, [scope_vector]).set_scope(scope)
    end

    def sync_scope(record)
      joined = @scope_description.joins_with?(record, self)
      if joined 
        if React::State.has_observers?(self, "collection")
          reload_from_db
        else
          @out_of_date = true
        end
      end
    end

    def reload_from_db
      @out_of_date = false
      ReactiveRecord::Base.load_from_db(nil, *@vector, "*all") if @collection
      ReactiveRecord::Base.load_from_db(nil, *@vector, "*count")
    end

    def observed
      puts "observed #{self}  @out_of_date: #{!!@out_of_date}"
      reload_from_db if @out_of_date
      React::State.get_state(self, "collection") unless ReactiveRecord::Base.data_loading?
    end


    alias pre_synchromesh_instance_variable_set instance_variable_set

    def instance_variable_set(var, val)
      if var == :@count && !ReactiveRecord::WhileLoading.has_observers?
        React::State.set_state(self, "collection", collection, true)
      end
      pre_synchromesh_instance_variable_set var, val
    end

    alias_method :pre_synchromesh_push, '<<'

    def <<(item)
      puts "pushing #{item} onto collection"
      if collection
        puts "has collection"
        pre_synchromesh_push item
      elsif !@count.nil?
        puts "has count, updating"
        if item.destroyed?
          puts "destroyed, decrementing count"
          @count -= 1
          notify_of_change self
        else #if item.backing_record.new_id?
          puts "not destroyed incrementing count"
          @count += 1
          notify_of_change self
        end
      end
    end

    def update_collection_on_sync(ar_instance)
      puts "update_collection_on_sync(#{ar_instance})"
      if collection
        puts "has collection"
        self << ar_instance
      elsif ar_instance.destroyed?
        puts "destroyed"
        @count -= 1
        notify_of_change self
        puts "notified"
      elsif ar_instance.backing_record.new_id?
        puts "new_id is true"
        @count += 1
        notify_of_change self
      end
    end
  end
end
