module ReactiveRecord
  module Operations
  # fetch queued up records from the server
    class Fetch < Hyperloop::ServerOp
      param :acting_user, nils: true
      param models: []
      param associations: []
      param :pending_fetches
      step do
        ReactiveRecord::ServerDataCache[
          params.models.map(&:with_indifferent_access),
          params.associations.map(&:with_indifferent_access),
          params.pending_fetches,
          params.acting_user
        ]
      end
      #fail { {error: e.message, backtrace: e.backtrace} }
    end

    class Save < Hyperloop::ServerOp
      param :acting_user, nils: true
      param models: []
      param associations: []
      param :validate, type: :boolean

      step do
        ReactiveRecord::Base.save_records(
          params.models.map(&:with_indifferent_access),
          params.associations.map(&:with_indifferent_access),
          params.acting_user,
          params.validate,
          true
        )
      end
    end

    class Destroy < Hyperloop::ServerOp
      param :acting_user, nils: true
      param :model
      param :id
      param :vector
      step do
        ReactiveRecord::Base.destroy_record(
          params.model,
          params.id,
          params.vector,
          params.acting_user
        )
      end
    end
  end
end
