module ActiveRecord
  # adds method to get the HyperMesh public column types
  # for now we are just getting all models column types, but we should
  # look through the public folder, and just get those models.
  # this works because the public folder is currently required to be eaer loaded.
  class Base
    def self.public_columns_hash
      return @public_columns_hash if @public_columns_hash
      @public_columns_hash = {}
      descendants.each do |model|
        @public_columns_hash[model.name] = model.columns_hash
        #model.columns_hash.each { |k, v| hash[k] = v.type }
      end
      @public_columns_hash
    end
  end
end
