module ReactiveRecord
  # Add the when_not_saving method to reactive-record.
  # This will wait until reactive-record is not saving a model.
  # Currently there is no easy way to do this without polling.
  class Base

    def sync_scopes
      # all changes will be rebroadcast and updated by sync_scopes2 so this is now a no-op
    end

    def sync_scopes2
      Collection.sync_scopes(@ar_instance)
      model.all << @ar_instance if ReactiveRecord::Base.class_scopes(model)[:all] # add this only if model.all has been fetched already
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

    # def set_previous_changes(hash)
    #   @previous_changes = {}
    #   hash.each { |attr, new_value| @previous_changes[attr] = [@attributes[attr], new_value] }
    # end
    #
    # alias pre_synchromesh_sync! sync!
    #
    # def sync!(hash={})
    #   set_previous_changes(hash)
    #   pre_synchromesh_sync!(hash)
    # end

  end
end
