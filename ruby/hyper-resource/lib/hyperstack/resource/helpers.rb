module Hyperstack
  module Resource
    module Helpers
      def self.collection_from_json_array(array, record = nil, relation_name = nil)
        res = array.map do |record_hash|
          Hyperstack::Resource::Helpers.record_from_hash(record_hash)
        end
        HyperRecord::Collection.new(res, record, relation_name)
      end

      def self.record_from_hash(record_hash)
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

        record.class._class_fetch_states["record_#{id}"] = 'f'
        record
      end

      def self.convert_hashes_to_collection(record_hashes, record = nil, relation_name = nil)
        res = []
        record_hashes.keys.each do |model_name|
          model = model_name.camelize.constantize
          record_hashes[model_name].keys.each do |id|
            record = if model.record_cached?(id)
                       model._record_cache[id]._initialize_from_hash(record_hashes[model_name][id]['properties'])
                     else
                       model.new(record_hashes[model_name][id]['properties'])
                     end
            res << record
          end
        end
        HyperRecord::Collection.new(res, record, relation_name)
      end
    end
  end
end