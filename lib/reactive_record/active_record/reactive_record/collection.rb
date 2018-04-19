module ReactiveRecord

  class Collection

    class DummySet
      def new
        @master ||= super
      end
      def method_missing(*args)
      end
    end

    def unsaved_children
      old_uc_already_being_called = @uc_already_being_called
      if @owner && @association
        @unsaved_children ||= Set.new
        unless @uc_already_being_called
          @uc_already_being_called = true
        end
      else
        @unsaved_children ||= DummySet.new
      end
      @unsaved_children
    ensure
      @uc_already_being_called = old_uc_already_being_called
    end

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
          new_dummy_record.attributes[@association.inverse_of] = @owner if @association && !@association.through_association?
          @collection << new_dummy_record
        end
      end
      @collection[index]
    end

    def ==(other_collection)
      observed
      return !@collection unless other_collection.is_a? Collection
      other_collection.observed
      my_children = (@collection || []).select { |target| target != @dummy_record }
      if other_collection
        other_children = (other_collection.collection || []).select { |target| target != other_collection.dummy_record }
        return false unless my_children == other_children
        unsaved_children.to_a == other_collection.unsaved_children.to_a
      else
        my_children.empty? && unsaved_children.empty?
      end
    end
    # todo move following to a separate module related to scope updates ******************
    attr_reader   :vector
    attr_writer   :scope_description
    attr_writer   :parent
    attr_reader   :pre_sync_related_records

    def to_s
      "<Coll-#{object_id} owner: #{@owner}, parent: #{@parent} - #{vector}>"
    end

    class << self

=begin
sync_scopes takes a newly broadcasted record change and updates all relevant currently active scopes
This is particularly hard when the client proc is specified.  For example consider this scope:

class TestModel < ApplicationRecord
  scope :quicker, -> { where(completed: true) }, client: -> { completed }
end

and this slice of reactive code:

   DIV { "quicker.count = #{TestModel.quicker.count}" }

then on the server this code is executed:

  TestModel.last.update(completed: false)

This will result in the changes being broadcast to the client, which may cauase the value of
TestModel.quicker.count to increase or decrease.  Of course we may not actually have the all the records,
perhaps we just have the aggregate count.

To determine this sync_scopes first asks if the record being changed is in the scope given its value


=end
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
      true
    end

    # is it necessary to check @association in the next 2 methods???

    def joins_with?(record)
      klass = record.class
      if @association&.through_association
        @association.through_association.klass == record.class
      elsif @target_klass == klass
        true
      elsif !klass.inheritance_column
        false
      elsif klass.base_class == @target_class
        klass < @target_klass
      elsif klass.base_class == klass
        @target_klass < klass
      end
    end

    def related_records_for(record)
      return [] unless @association
      attrs = record.attributes
      return [] unless attrs[@association.inverse_of] == @owner
      if !@association.through_association
        [record]
      elsif (source = attrs[@association.source])
        [source]
      else
        []
      end
    end

    def collector?
      false
    end

    def filter_records(related_records)
      # possibly we should never get here???
      scope_args = @vector.last.is_a?(Array) ? @vector.last[1..-1] : []
      @scope_description.filter_records(related_records, scope_args)
    end

    def live_scopes
      @live_scopes ||= Set.new
    end

    def set_pre_sync_related_records(related_records, _record = nil)
      #related_records = related_records.intersection([*@collection]) <- deleting this works
      @pre_sync_related_records = related_records #in_this_collection related_records <- not sure if this works
      live_scopes.each { |scope| scope.set_pre_sync_related_records(@pre_sync_related_records) }
    end

    # NOTE sync_scopes is overridden in scope_description.rb
    def sync_scopes(related_records, record, filtering = true)
      #related_records = related_records.intersection([*@collection])
      #related_records = in_this_collection related_records
      live_scopes.each { |scope| scope.sync_scopes(related_records, record, filtering) }
      notify_of_change unless related_records.empty?
    ensure
      @pre_sync_related_records = nil
    end

    def apply_scope(name, *vector)
      description = ScopeDescription.find(@target_klass, name)
      collection = build_child_scope(description, *description.name, *vector)
      collection.reload_from_db if name == "#{description.name}!"
      collection
    end

    def child_scopes
      @child_scopes ||= {}
    end

    def build_child_scope(scope_description, *scope_vector)
      child_scopes[scope_vector] ||= begin
        new_vector = @vector
        new_vector += [scope_vector] unless new_vector.nil? || scope_vector.empty?
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
      elsif @parent._count_internal(false).zero?  # just changed this from count.zero?
        @count = 0
      end
    end

    # end of stuff to move

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

    def set_count_state(val)
      unless ReactiveRecord::WhileLoading.has_observers?
        React::State.set_state(self, :collection, collection, true)
      end
      @count = val
    end



    def _count_internal(load_from_client)
      # when count is called on a leaf, count_internal is called for each
      # ancestor.  Only the outermost count has load_from_client == true
      observed
      if @collection
        @collection.count
      elsif @count ||= ReactiveRecord::Base.fetch_from_db([*@vector, "*count"])
        @count
      else
        ReactiveRecord::Base.load_from_db(nil, *@vector, "*count") if load_from_client
        @count = 1
      end
    end

    def count
      _count_internal(true)
    end

    alias_method :length, :count

    # WHY IS THIS NEEDED?  Perhaps it was just for debug
    def collect(*args, &block)
      all.collect(*args, &block)
    end

    # def each_known_child
    #   [*collection, *client_pushes].each { |i| yield i }
    # end

    def proxy_association
      @association || self # returning self allows this to work with things like Model.all
    end

    def klass
      @target_klass
    end

    def push_and_update_belongs_to(id)
      # example collection vector: TestModel.find(1).child_models.harrybarry
      # harrybarry << child means that
      # child.test_model = 1
      # so... we go back starting at this collection and look for the first
      # collection with an owner... that is our guy
      child = proxy_association.klass.find(id)
      push child
      set_belongs_to child
    end

    def set_belongs_to(child)
      if @owner
        # TODO this is major broken...current
        child.send("#{@association.inverse_of}=", @owner) if @association && !@association.through_association
      elsif @parent
        @parent.set_belongs_to(child)
      end
      child
    end

    attr_reader :client_collection

    # appointment.doctor = doctor_value (i.e. through association is changing)
    # means appointment.doctor_value.patients << appointment.patient
    # and we have to appointment.doctor(current value).patients.delete(appointment.patient)

    def update_child(item)
      backing_record = item.backing_record
      if backing_record && @owner && @association && !@association.through_association? && item.attributes[@association.inverse_of] != @owner
        inverse_of = @association.inverse_of
        current_association = item.attributes[inverse_of]
        backing_record.virgin = false unless backing_record.data_loading?
        backing_record.update_belongs_to(inverse_of, @owner)
        if current_association && current_association.attributes[@association.attribute]
          current_association.attributes[@association.attribute].delete(item)
        end
        @owner.backing_record.sync_has_many(@association.attribute)
      end
    end

    def push(item)
      item.itself # force get of at least the id
      if collection
        self.force_push item
      else
        unsaved_children << item
        update_child(item)
        @owner.backing_record.sync_has_many(@association.attribute) if @owner && @association
        if !@count.nil?
          @count += item.destroyed? ? -1 : 1
          notify_of_change self
        end
      end
      self
    end

    alias << push

    def sort!(*args, &block)
      replace(sort(*args, &block))
    end

    def force_push(item)
      return delete(item) if item.destroyed? # pushing a destroyed item is the same as removing it
      all << item unless all.include? item # does this use == if so we are okay...
      update_child(item)
      if item.id and @dummy_record
        @dummy_record.id = item.id
        # we cant use == because that just means the objects are referencing
        # the same backing record.
        @collection.reject { |i| i.object_id == @dummy_record.object_id }
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
      unsaved_children.clear
      new_array = new_array.to_a
      return self if new_array == @collection
      Base.load_data { internal_replace(new_array) }
      notify_of_change new_array
    end

    def internal_replace(new_array)

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
      unsaved_children.delete(item)
      notify_of_change(
        if @owner && @association && !@association.through_association?
          inverse_of = @association.inverse_of
          if (backing_record = item.backing_record) && item.attributes[inverse_of] == @owner
            # the if prevents double update if delete is being called from << (see << above)
            backing_record.update_belongs_to(inverse_of, nil)
          end
          delete_internal(item) { @owner.backing_record.sync_has_many(@association.attribute) }
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
      yield if block_given? # was yield item, but item is not used
      item
    end

    def loading?
      all # need to force initialization at this point
      @dummy_collection.loading?
    end

    def empty?
      # should be handled by method missing below, but opal-rspec does not deal well
      # with method missing, so to test...
      all.empty?
    end

    def method_missing(method, *args, &block)
      if [].respond_to? method
        all.send(method, *args, &block)
      elsif ScopeDescription.find(@target_klass, method)
        apply_scope(method, *args)
      elsif args.count == 1 && method.start_with?('find_by_')
        apply_scope(:find_by, method.sub(/^find_by_/, '') => args.first)
      elsif @target_klass.respond_to?(method) && ScopeDescription.find(@target_klass, "_#{method}")
        apply_scope("_#{method}", *args).first
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

  end

end
