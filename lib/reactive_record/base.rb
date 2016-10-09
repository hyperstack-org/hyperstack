module ReactiveRecord
  # Add the when_not_saving method to reactive-record.
  # This will wait until reactive-record is not saving a model.
  # Currently there is no easy way to do this without polling.
  class Base

    def sync_scopes
      # all changes will be rebroadcast and updated by sync_scopes2 so this now a NOP, otherwise
      # we end up syncing twice - once when we save (which calls sync_scopes) and again
      # when synchromesh broadcasts the change.
      # The only iffy thing is that you might have permission to update the record and save it
      # but yet not have a policy to get the syncronized updates.  This needs to be worked
      # probably by making all authorizations work through the same policy mechanisms, Instead
      # of having the distinct mechanism for synchromesh vs. reactive-record.
      #sync_scopes2 if Synchromesh::ClientDrivers.opts[:transport] == :none
      sync_unscoped_collection!
    end

    def sync_unscoped_collection!
      if destroyed
        return if @destroy_sync
        @destroy_sync = true
      else
        return if @create_sync
        @create_sync = true
      end
      puts "pushing #{ar_instance} onto #{model}.unscoped (#{model.unscoped}) "
      model.unscoped << ar_instance
      @synced_with_unscoped = !@synced_with_unscoped
    end

    def self.exists?(model, id)
      exists = @records[model].detect { |record| record.attributes[model.primary_key] == id }
    end

    attr_accessor :currently_in_default_scope
    attr_accessor :current_default_scope_count

    def self.all_class_scopes  #UNDUP THESE... JUST FOR DEBUG>>>>>
      Enumerator.new do |y|
        @class_scopes.dup.each_value { |scopes| scopes.dup.each_value { |scope| y << scope }}
      end
    end

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

    class << self

      class DbRequestMade < Exception; end

      def catch_db_requests(return_val = nil)
        @catch_db_requests = true
        return_val = yield
      rescue DbRequestMade => e
        puts "Warning request for server side data during scope evaluation: #{e.message}"
      ensure
        @catch_db_requests = false
        return return_val
      end

      alias pre_synchromesh_load_from_db load_from_db

      def load_from_db(*args)
        raise DbRequestMade.new(args) if @catch_db_requests
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
