module ActiveRecord
  # adds method to get the HyperMesh public column types
  # for now we are just getting all models column types, but we should
  # look through the public folder, and just get those models.
  # this works because the public folder is currently required to be eaer loaded.
  class Base
    def self.public_columns_hash
      return @public_columns_hash if @public_columns_hash
      Dir.glob(Rails.root.join('app/models/public/*.rb')).each do |file|
        require_dependency(file) rescue nil
      end
      @public_columns_hash = {}
      descendants.each do |model|
        @public_columns_hash[model.name] = model.columns_hash
      end
      @public_columns_hash
    end
  end
end
