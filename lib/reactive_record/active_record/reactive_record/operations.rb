module ReactiveRecord
  # redefine if you want to process errors (i.e. logging, rollbar, etc)
  def self.on_fetch_error(e, params); end

  # associations: {parent_id: record.object_id, attribute: attribute, child_id: assoc_record.object_id}
  # models: {id: record.object_id, model: record.model.model_name, attributes: changed_attributes}

  module Operations
    # to make debug easier we convert all the object_id strings to be hex representation
    class Base < Hyperloop::ControllerOp
      param :acting_user, nils: true

      FORMAT = '0x%x'

      def self.serialize_params(hash)
        hash['associations'].each do |assoc|
          assoc['parent_id'] = FORMAT % assoc['parent_id']
          assoc['child_id'] = FORMAT % assoc['child_id']
        end if hash['associations']
        hash['models'].each do |assoc|
          assoc['id'] = FORMAT % assoc[:id]
        end if hash['models']
        hash
      end

      def self.deserialize_params(hash)
        hash['associations'].each do |assoc|
          assoc['parent_id'] = assoc['parent_id'].to_i(16)
          assoc['child_id'] = assoc['child_id'].to_i(16)
        end if hash['associations']
        hash['models'].each do |assoc|
          assoc['id'] = assoc['id'].to_i(16)
        end if hash['models']
        hash
      end

      def self.serialize_response(response)
        response[:saved_models].each do |saved_model|
          saved_model[0] = FORMAT % saved_model[0]
        end if response.is_a?(Hash) && response[:saved_models]
        response
      end

      def self.deserialize_response(response)
        response[:saved_models].each do |saved_model|
          saved_model[0] = saved_model[0].to_i(16)
        end if response.is_a?(Hash) && response[:saved_models]
        response
      end
    end
    # fetch queued up records from the server
    # subclass of ControllerOp so we can pass the controller
    # along to on_fetch_error
    class Fetch < Base
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

    class Save < Base
      param :acting_user, nils: true
      param models: []
      param associations: []
      param :save, type: :boolean
      param :validate, type: :boolean

      step do
        ReactiveRecord::Base.save_records(
          params.models.map(&:with_indifferent_access),
          params.associations.map(&:with_indifferent_access),
          params.acting_user,
          params.validate,
          params.save
        )
      end
    end

    class Destroy < Base
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
