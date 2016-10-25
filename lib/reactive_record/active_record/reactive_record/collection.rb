module ReactiveRecord

  class Collection

    def initialize(target_klass, owner = nil, association = nil, *vector)
      @owner = owner  # can be nil if this is an outer most scope
      @association = association
      @target_klass = target_klass
      if owner and !owner.id and vector.length <= 1
        @collection = []
      elsif vector.length > 0
        @vector = vector
      elsif owner
        @vector = owner.backing_record.vector + [association.attribute]
      else
        @vector = [target_klass]
      end
      @scopes = {}
    end

    def dup_for_sync
      self.dup.instance_eval do
        @collection = @collection.dup if @collection
        @scopes = @scopes.dup
        self
      end
    end

    def all
      observed
      @dummy_collection.notify if @dummy_collection
      unless @collection
        @collection = []
        if ids = ReactiveRecord::Base.fetch_from_db([*@vector, "*all"])
          ids.each do |id|
            @collection << @target_klass.find_by(@target_klass.primary_key => id)
          end
        else
          @dummy_collection = ReactiveRecord::Base.load_from_db(nil, *@vector, "*all")
          @dummy_record = self[0]
        end
      end
      @collection
    end

    def [](index)
      observed
      if (@collection || all).length <= index and @dummy_collection
        (@collection.length..index).each do |i|
          new_dummy_record = ReactiveRecord::Base.new_from_vector(@target_klass, nil, *@vector, "*#{i}")
          new_dummy_record.backing_record.attributes[@association.inverse_of] = @owner if @association and @association.inverse_of
          @collection << new_dummy_record
        end
      end
      @collection[index]
    end

    def ==(other_collection)
      observed
      return !@collection unless other_collection.is_a? Collection
      other_collection.observed
      my_collection = (@collection || []).select { |target| target != @dummy_record }
      other_collection = (other_collection ? (other_collection.collection || []) : []).select { |target| target != other_collection.dummy_record }
      my_collection == other_collection
    end

    def apply_scope(scope, *args)
      # The value returned is another ReactiveRecordCollection with the scope added to the vector
      # no additional action is taken
      scope = [scope, *args] if args.count > 0
      @scopes[scope] ||= Collection.new(@target_klass, @owner, @association, *@vector, [scope])
    end

    def count
      observed
      if @collection
        @collection.count
      elsif @count ||= ReactiveRecord::Base.fetch_from_db([*@vector, "*count"])
        @count
      else
        ReactiveRecord::Base.load_from_db(nil, *@vector, "*count")
        @count = 1
      end
    end

    alias_method :length, :count

    def proxy_association
      @association || self # returning self allows this to work with things like Model.all
    end

    def klass
      @target_klass
    end

    def <<(item)
      return delete(item) if item.destroyed? # pushing a destroyed item is the same as removing it
      backing_record = item.backing_record
      all << item unless all.include? item # does this use == if so we are okay...
      if backing_record and @owner and @association and inverse_of = @association.inverse_of and item.attributes[inverse_of] != @owner
        current_association = item.attributes[inverse_of]
        backing_record.virgin = false unless backing_record.data_loading?
        backing_record.update_attribute(inverse_of, @owner)
        current_association.attributes[@association.attribute].delete(item) if current_association and current_association.attributes[@association.attribute]
        @owner.backing_record.update_attribute(@association.attribute) # forces a check if association contents have changed from synced values
      end
      if item.id and @dummy_record
        @dummy_record.id = item.id
        @collection.delete(@dummy_record)
        @dummy_record = @collection.detect { |r| r.backing_record.vector.last =~ /^\*[0-9]+$/ }
        @dummy_collection = nil
      end
      notify_of_change self
    end

    [:first, :last].each do |method|
      define_method method do |*args|
        if args.count == 0
          all.send(method)
        else
          apply_scope(method, *args)
        end
      end
    end

    def replace(new_array)

      # not tested if you do all[n] where n > 0... this will create additional dummy items, that this will not sync up.
      # probably just moving things around so the @dummy_collection and @dummy_record are updated AFTER the new items are pushed
      # should work.

      if @dummy_collection
        @dummy_collection.notify
        array = new_array.is_a?(Collection) ? new_array.collection : new_array
        @collection.each_with_index do |r, i|
          r.id = new_array[i].id if array[i] and array[i].id and !r.new? and r.backing_record.vector.last =~ /^\*[0-9]+$/
        end
      end

      @collection.dup.each { |item| delete(item) } if @collection  # this line is a big nop I think
      @collection = []
      if new_array.is_a? Collection
        @dummy_collection = new_array.dummy_collection
        @dummy_record = new_array.dummy_record
        new_array.collection.each { |item| self << item } if new_array.collection
      else
        @dummy_collection = @dummy_record = nil
        new_array.each { |item| self << item }
      end
      notify_of_change new_array
    end

    def delete(item)
      notify_of_change(if @owner and @association and inverse_of = @association.inverse_of
        if backing_record = item.backing_record and backing_record.attributes[inverse_of] == @owner
          # the if prevents double update if delete is being called from << (see << above)
          backing_record.update_attribute(inverse_of, nil)
        end
        all.delete(item).tap { @owner.backing_record.update_attribute(@association.attribute) } # forces a check if association contents have changed from synced values
      else
        all.delete(item)
      end)
    end

    def loading?
      all # need to force initialization at this point
      @dummy_collection.loading?
    end

    def empty?  # should be handled by method missing below, but opal-rspec does not deal well with method missing, so to test...
      all.empty?
    end

    def method_missing(method, *args, &block)
      if [].respond_to? method
        all.send(method, *args, &block)
      elsif @target_klass.respond_to?(method) or (args.count == 1 && method =~ /^find_by_/)
        apply_scope(method, *args)
      else
        super
      end
    end

    protected

    def dummy_record
      @dummy_record
    end

    def collection
      @collection
    end

    def dummy_collection
      @dummy_collection
    end

    def notify_of_change(value = nil)
      React::State.set_state(self, "collection", collection) unless ReactiveRecord::Base.data_loading?
      value
    end

    def observed
      React::State.get_state(self, "collection") unless ReactiveRecord::Base.data_loading?
    end

  end

end
