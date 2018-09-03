module Hyperstack
  module Model
    module Helpers
      def self.collection_from_transport_array(array, record = nil, relation_name = nil)
        res = array.map do |record_hash|
          Hyperstack::Model::Helpers.record_from_transport_hash(record_hash)
        end
        Hyperstack::Record::Collection.new(res, record, relation_name)
      end

      def self.record_from_transport_hash(record_hash)
        return nil if !record_hash
        model_name = record_hash.keys.first
        return nil if model_name == 'nil_class'
        return nil if !record_hash[model_name]
        return nil if record_hash[model_name].keys.size == 0

        model = model_name.camelize.constantize
        id = record_hash[model_name]['instances'].keys.first.to_s

        record = model._record_cache[id]

        if record.nil?
          record = model.new(record_hash[model_name]['instances'][id]['properties'])
        else
          record._initialize_from_hash(record_hash[model_name]['instances'][id]['properties'])
        end

        record.class._class_read_states["record_#{id}"] = 'f'
        record
      end
    end
  end
end