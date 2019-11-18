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
      if owner && !owner.id && vector.length <= 1
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
      # unless false && @collection # this fixes https://github.com/hyperstack-org/hyperstack/issues/82 in very limited cases, and breaks otherthings
      #   sync_collection_with_parent
      # end
      unless @collection
        @collection = []
        if ids = ReactiveRecord::Base.fetch_from_db([*@vector, "*all"])
          ids.each do |id|
            @collection << ReactiveRecord::Base.find_by_id(@target_klass, id)
          end
        else
          @dummy_collection = ReactiveRecord::Base.load_from_db(nil, *@vector, "*all")
          # this calls back to all now that the collection is initialized,
          # so it has the side effect of creating a dummy value in collection[0]
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
          # HMT-TODO: the above needs to be looked into... if we are a hmt then don't we need to create a dummy on the joins collection as well?
          # or maybe this just does not work for HMT?
          @collection << new_dummy_record
        end
      end
      @collection[index]
    end

    def ==(other_collection)
      observed
      # handle special case of other_collection NOT being a collection (typically nil)
      return (@collection || []) == other_collection unless other_collection.is_a? Collection
      other_collection.observed
      # if either collection has not been created then compare the vectors
      # https://github.com/hyperstack-org/hyperstack/issues/81
      # TODO: if this works then remove the || [] below (2 of them)
      if !@collection || !other_collection.collection
        return @vector == other_collection.vector && unsaved_children == other_collection.unsaved_children
      end
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
    attr_accessor :scope_description
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
        Hyperstack::Internal::State::Mapper.bulk_update do
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
      elsif (source = attrs[@association.source]) && source.is_a?(@target_klass)
        [source]
      else
        []
      end
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

    def in_this_collection(related_records)
      # HMT-TODO: I don't think we can get a set of related records here with a through association unless they are part of the collection
      return related_records if !@association || @association.through_association?
      related_records.select do |r|
        r.backing_record.attributes[@association.inverse_of] == @owner
      end
    end

    def set_pre_sync_related_records(related_records, _record = nil)
      @pre_sync_related_records = in_this_collection(related_records)
      live_scopes.each { |scope| scope.set_pre_sync_related_records(@pre_sync_related_records) }
    end

    # NOTE sync_scopes is overridden in scope_description.rb
    def sync_scopes(related_records, record, filtering = true)
      #related_records = related_records.intersection([*@collection])
      related_records = in_this_collection(related_records) if filtering
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
      # puts "#{self}.link_to_parent @linked = #{!!@linked}, collection? #{!!@collection}"
      # always check that parent is synced  - fixes issue https://github.com/hyperstack-org/hyperstack/issues/82
      # note that sync_collection_with_parent checks to make sure that is NOT a collection and that there IS a parent

      return sync_collection_with_parent if @linked
      @linked = true
      if @parent
        @parent.link_child self
        sync_collection_with_parent
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
      # puts "#{self}.sync_collection_with_parent"
      return if @collection || !@parent || @parent.dummy_collection # fixes issue https://github.com/hyperstack-org/hyperstack/issues/78 and supports /82
      if @parent.collection
        # puts ">>> @parent.collection present"
        if @parent.collection.empty?
          # puts ">>>>> @parent.collection is empty!"
          @collection = []
        elsif filter?
          # puts "#{self}.sync_collection_with_parent (@parent = #{@parent}) calling filter records on (#{@parent.collection})"
          @collection = filter_records(@parent.collection).to_a
        end
      elsif !@linked && @parent._count_internal(false).zero?
        # don't check _count_internal if already linked as this cause an unnecessary rendering cycle
        # puts ">>> @parent._count_internal(false).zero? is true!"
        @count = 0
      else
        # puts ">>> NOP"
      end
    end

    # end of stuff to move

    def reload_from_db(force = nil)
      if force || Hyperstack::Internal::State::Variable.observed?(self, :collection)
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
        Hyperstack::Internal::State::Variable.get(self, :collection)
      ensure
        @observing = false
      end
    end

    def set_count_state(val)
      unless ReactiveRecord::WhileLoading.observed?
        Hyperstack::Internal::State::Variable.set(self, :collection, collection, true)
      end
      @count = val
    end



    def _count_internal(load_from_client)
      # when count is called on a leaf, count_internal is called for each
      # ancestor.  Only the outermost count has load_from_client == true
      observed
      if @count && @dummy_collection
        @count # fixes https://github.com/hyperstack-org/hyperstack/issues/79
      elsif @collection
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
      child = ReactiveRecord::Base.find_by_id(proxy_association.klass, id)
      push child
      set_belongs_to child
    end

    def set_belongs_to(child)
      if @owner
        # TODO this is major broken...current
        if (through_association = @association.through_association)
          # HMT-TODO: create a new record with owner and child
        else
          child.send("#{@association.inverse_of}=", @owner) if @association && !@association.through_association
        end
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
      # HMT TODO:  The following && !association.through_association was commented out, causing wrong class items to be added to
      # associations
      # Why was it commented out.
      if backing_record && @owner && @association && item.attributes[@association.inverse_of] != @owner && !@association.through_association?
        inverse_of = @association.inverse_of
        current_association_value = item.attributes[inverse_of]
        backing_record.virgin = false unless backing_record.data_loading?
        # next line was commented out and following line was active.
        backing_record.update_belongs_to(inverse_of, @owner)
        #backing_record.set_belongs_to_via_has_many(@association, @owner)
        # following is handled by update_belongs_to and is redundant
        # unless current_association_value.nil?  # might be a dummy value which responds to nil
        #   current_association = @association.inverse.inverse(current_association_value)
        #   current_association_attribute = current_association.attribute
        #   if current_association.collection? && current_association_value.attributes[current_association_attribute]
        #     current_association.attributes[current_association_attribute].delete(item)
        #   end
        # end
        @owner.backing_record.sync_has_many(@association.attribute)
      end
    end

    def push(item)
      if (through_association = @association&.through_association)
        through_association.klass.create(@association.inverse_of => @owner, @association.source => item)
        self
      else
        _internal_push(item)
      end
    end

    alias << push

    def _internal_push(item)
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

    # [:first, :last].each do |method|
    #   define_method method do |*args|
    #     if args.count == 0
    #       all.send(method)
    #     else
    #       apply_scope(method, *args)
    #     end
    #   end
    # end

    def first(n = nil)
      if n
        apply_scope(:first, n)
      else
        self[0]
      end
    end

    def last(n = nil)
      if n
        apply_scope(:__hyperstack_internal_scoped_last_n, n)
      else
        __hyperstack_internal_scoped_last
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
          r.id = new_array[i].id if array[i] and array[i].id and !r.new_record? and r.backing_record.vector.last =~ /^\*[0-9]+$/
        end
      end
      # the following makes sure that the existing elements are properly removed from the collection
      @collection.dup.each { |item| delete(item) } if @collection
      @collection = []
      if new_array.is_a? Collection
        @dummy_collection = new_array.dummy_collection
        @dummy_record = new_array.dummy_record
        new_array.collection.each { |item| _internal_push item } if new_array.collection
      else
        @dummy_collection = @dummy_record = nil
        new_array.each { |item| _internal_push item }
      end
      notify_of_change new_array
    end

    def delete(item)
      Hyperstack::Internal::State::Mapper.bulk_update do
        unsaved_children.delete(item)
        if @owner && @association
          inverse_of = @association.inverse_of
          if (backing_record = item.backing_record) && item.attributes[inverse_of] == @owner && !@association.through_association?
            # the if prevents double update if delete is being called from << (see << above)
            backing_record.update_belongs_to(inverse_of, nil)
          end
          delete_internal(item) { @owner.backing_record.sync_has_many(@association.attribute) }
        else
          delete_internal(item)
        end.tap { Hyperstack::Internal::State::Variable.set(self, :collection, collection) }
      end
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

    def find_by(attrs)
      attrs = @target_klass.__hyperstack_preprocess_attrs(attrs)
      (r = __hyperstack_internal_scoped_find_by(attrs)) || return
      r.backing_record.sync_attributes(attrs).set_ar_instance!
    end

    def find(*args)
      args = args[0] if args[0].is_a? Array
      return args.collect { |id| find(id) } if args.count > 1
      find_by(@target_klass.primary_key => args[0])
    end

    def _find_by_initializer(scope, attrs)
      found =
        if scope.is_a? Collection
          scope.parent.collection&.detect { |lr| !attrs.detect { |k, v| lr.attributes[k] != v } }
        else
          ReactiveRecord::Base.find_locally(@target_klass, attrs)&.ar_instance
        end
      return first unless found
      @collection = [found]
      found
    end

    # to avoid fetching the entire collection array we check empty and any against the count

    def empty?
      count.zero?
    end

    def any?(*args, &block)
      # If are doing anything other than just checking if there is an object in the collection,
      # proceed to the normal behavior
      return super if args&.length&.positive? || block.present?

      # Otherwise just check the count for efficiency
      count.positive?
    end

    def method_missing(method, *args, &block)
      if args.count == 1 && method.start_with?('find_by_')
        find_by(method.sub(/^find_by_/, '') => args[0])
      elsif [].respond_to? method
        all.send(method, *args, &block)
      elsif ScopeDescription.find(@target_klass, method)
        apply_scope(method, *args)
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
      Hyperstack::Internal::State::Variable.set(self, "collection", collection) unless ReactiveRecord::Base.data_loading?
      value
    end
  end

end
