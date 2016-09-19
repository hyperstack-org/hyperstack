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
    end

    def sync_scopes2
      puts "********** sync_scopes2 called on #{self} *************"
      Collection.sync_scopes(@ar_instance)
      model.all << @ar_instance if ReactiveRecord::Base.class_scopes(model)[:all]
      # collection.update_collection_on_sync(@ar_instance) if collection # update the collection only if it exists
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

    attr_writer :previous_changes

    def previous_changes
      @previous_changes ||= {}
    end

    def new_id?
      previous_changes[:id] && `#{previous_changes[:id]}[0] == null`
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
