module ReactiveRecord

  class Collection

    attr_reader :vector
    attr_reader :scope_description

    class << self
      def add_scope(klass, name, opts)
        scope_descriptions[klass][name] = ScopeDescription.new(name, klass, opts)
      end

      def add_scoped_collection(klass, scope, collection)
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
      if collection
        pre_synchromesh_push item
      elsif !@count.nil?
        @count += item.destroyed? ? -1 : 1
        notify_of_change self
      end
    end

    def delete(item)
      notify_of_change(if @owner and @association and inverse_of = @association.inverse_of
        if backing_record = item.backing_record and backing_record.attributes[inverse_of] == @owner
          # the if prevents double update if delete is being called from << (see << above)
          backing_record.update_attribute(inverse_of, nil)
        end
        delete_internal(item) { @owner.backing_record.update_attribute(@association.attribute) } # forces a check if association contents have changed from synced values
      else
        delete_internal(item)
      end)
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

    def update_collection_on_sync(ar_instance, count, in_scope)
      if count
        if collection
          if in_scope
            self << ar_instance
          else
            self.delete(ar_instance)
          end
          if self.count != count
            reload_from_db
          end
        elsif !@count.nil?
          @count = count
          notify_of_change self
        end
      else
        self << ar_instance
      end
    end
  end
end
