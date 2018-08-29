module HyperRecord
  module ServerInstanceMethods
    def to_transport_hash
      record_model = self.class.to_s.underscore
      record_json = self.as_json
      props = if record_json.has_key?(record_model)
                record_json[record_model] # for Neo4j
              else
                record_json # for ActiveRecord
              end
      { record_model => { instances: { self.id.to_s => { properties: props }}}}
    end
  end
end