module ReactiveRecord
  # patches and new methods
  class Base
    # replacement for sync_scopes
    # def sync_scopes
    #   sync_unscoped_collection!
    # end

    # called when we have a newly created record, to initialize
    # any nil collections to empty arrays.  We can do this because
    # if its a brand new record, then any collections that are still
    # nil must not have any children.
    def initialize_collections
      if (!vector || vector.empty?) && id && id != ''
        @vector = [@model, ["find_by_#{@model.primary_key}", id]]
      end
      @model.reflect_on_all_associations.each do |assoc|
        if assoc.collection? && attributes[assoc.attribute].nil?
          ar_instance.send("#{assoc.attribute}=", [])
        end
      end
    end

    # sync! now will also initialize any nil collections
    def sync!(hash = {}) # does NOT notify (see saved! for notification)
      @attributes.merge! hash
      @synced_attributes = {}
      @synced_attributes.each { |attribute, value| sync_attribute(key, value) }
      @changed_attributes = []
      @saving = false
      @errors = nil
      # set the vector and clear collections - this only happens when a new record is saved
      initialize_collections if (!vector || vector.empty?) && id && id != ''
      self
    end

    # this keeps the unscoped collection up to date.
    # @destroy_sync and @create_sync prevent multiple insertions
    # to collections that just have a count
    def sync_unscoped_collection!
      if destroyed
        return if @destroy_sync
        @destroy_sync = true
      else
        return if @create_sync
        @create_sync = true
      end
      model.unscoped << ar_instance
      @synced_with_unscoped = !@synced_with_unscoped
    end

    # helper so we can tell if model exists.  We need this so we can detect
    # if a record has local changes that are out of sync.
    def self.exists?(model, id)
      @records[model].detect { |record| record.attributes[model.primary_key] == id }
    end

    # outer scopes are all collections (scopes and children) directly created off the model.
    before_first_mount do
      @outer_scopes = Set.new if RUBY_ENGINE == 'opal'
    end

    class << self
      attr_reader :outer_scopes

      def default_scope
        @class_scopes[:default_scope]
      end

      def unscoped
        @class_scopes[:unscoped]
      end

      def add_to_outer_scopes(item)
        @outer_scopes << item
      end
    end

    # when_not_saving will wait until reactive-record is not saving a model.
    # Currently there is no easy way to do this without polling.
    def self.when_not_saving(model)
      if @records[model].detect(&:saving?)
        poller = every(0.1) do
          unless @records[model].detect(&:saving?)
            poller.stop
            yield model
          end
        end
      else
        yield model
      end
    end

    # While evaluating scopes we want to catch any requests
    # to the server.  Once we catch any requests to the server
    # then all the further scopes in that chain will be made
    # at the server.

    class << self
      class DbRequestMade < RuntimeError; end

      def catch_db_requests(return_val = nil)
        @catch_db_requests = true
        yield
      rescue DbRequestMade => e
        puts "Warning request for server side data during scope evaluation: #{e.message}"
        return_val
      ensure
        @catch_db_requests = false
      end

      alias pre_synchromesh_load_from_db load_from_db

      def load_from_db(*args)
        raise DbRequestMade, args if @catch_db_requests
        pre_synchromesh_load_from_db(*args)
      end
    end

    # once this method is integrated back into reactive-record, remove the duplicate
    # code from within the destroy method (in file isomorphic_base)
    def destroy_associations
      model.reflect_on_all_associations.each do |association|
        if association.collection?
          attributes[association.attribute].replace([]) if attributes[association.attribute]
        else
          @ar_instance.send("#{association.attribute}=", nil)
        end
      end
    end
  end
end
