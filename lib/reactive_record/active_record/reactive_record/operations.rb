module ReactiveRecord
  # redefine if you want to process errors (i.e. logging, rollbar, etc)
  def self.on_fetch_error(e, params); end

  module Operations
    # fetch queued up records from the server
    # subclass of ControllerOp so we can pass the controller
    # along to on_fetch_error
    class Fetch < Hyperloop::ControllerOp
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
      failed do |e|
        ReactiveRecord.on_fetch_error(e, params.to_h)
        raise e
      end
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
