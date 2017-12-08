module Hyperloop
  define_setting :public_model_directories, ['app/models/public', 'app/hyperloop/models']
end

module ActiveRecord
  # adds method to get the HyperMesh public column types
  # for now we are just getting all models column types, but we should
  # look through the public folder, and just get those models.
  # this works because the public folder is currently required to be eaer loaded.
  class Base
    def self.public_columns_hash
      return @public_columns_hash if @public_columns_hash
      Hyperloop.public_model_directories.each do |dir|
        Dir.glob(Rails.root.join("#{dir}/**/*.rb")).each do |file|
          require_dependency(file)
        end
      end
      @public_columns_hash = {}
      descendants.each do |model|
        begin
          public_columns_hash[model.name] = model.columns_hash if model.table_name
        rescue Exception => e
          @public_columns_hash = nil
          raise $!, "Could not read 'columns_hash' for #{model}: #{$!}", $!.backtrace
        end
      end
      @public_columns_hash
    end
  end
end
