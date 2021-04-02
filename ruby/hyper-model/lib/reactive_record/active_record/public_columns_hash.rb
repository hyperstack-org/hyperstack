module Hyperstack
  define_setting :public_model_directories, [File.join('app','hyperstack','models'), File.join('app','models','public')]
end

module ActiveRecord
  # adds method to get the HyperMesh public column types
  # this works because the public folder is currently required to be eager loaded.
  class Base
    @@hyper_stack_public_columns_hash_mutex = Mutex.new
    def self.public_columns_hash
      @@hyper_stack_public_columns_hash_mutex.synchronize do
        return @public_columns_hash if @public_columns_hash && Rails.env.production?
        files = []
        Hyperstack.public_model_directories.each do |dir|
          dir_length = Rails.root.join(dir).to_s.length + 1
          Dir.glob(Rails.root.join(dir, '**', '*.rb')).each do |file|
            require_dependency(file) # still the file is loaded to make sure for development and test env
            files << file[dir_length..-4]
          end
        end
        @public_columns_hash = {}
        # descendants only works for already loaded models!
        descendants.each do |model|
          if files.include?(model.name.underscore) && model.name.underscore != 'application_record'
            @public_columns_hash[model.name] = model.columns_hash rescue nil # why rescue?
          end
        end
        @public_columns_hash
      end
    end

    @@hyper_stack_public_columns_hash_as_json_mutex = Mutex.new
    def self.public_columns_hash_as_json
      @@hyper_stack_public_columns_hash_as_json_mutex.synchronize do
        return @public_columns_hash_json if @public_columns_hash_json && Rails.env.production?
        pch = public_columns_hash
        return @public_columns_hash_json if @prev_public_columns_hash == pch
        @prev_public_columns_hash = pch
        @public_columns_hash_json = pch.to_json
      end
    end
  end
end
