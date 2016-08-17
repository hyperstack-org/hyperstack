module ReactiveRecord

  class Collection

    attr_reader :vector
    attr_reader :scope_description

    class << self
      def add_scope(klass, name, server_side_arg, joins_list, &block)
        scope_descriptions[klass][name] = ScopeDescription.new(klass, server_side_arg, joins_list, &block)
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
      joined = nil
      #ReactiveRecord::Base.load_data {}
      joined = @scope_description.joins_with?(record, self)
      puts "syncing #{self}-#{@vector} has_observers? #{React::State.has_observers?(self, 'collection')} joins? #{joined}"
      if joined #@scope_description.joins_with?(record, self)
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
  end
end
