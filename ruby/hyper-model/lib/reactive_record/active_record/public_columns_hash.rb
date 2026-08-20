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
        @public_columns_hash = {}
        Hyperstack.public_model_directories.each do |dir|
          dir_length = Rails.root.join(dir).to_s.length + 1
          Dir.glob(Rails.root.join(dir, '**', '*.rb')).each do |file|
            class_path = file[dir_length..-4]
            next if class_path == 'application_record'
            # Resolve the constant by name first: when the public-directory file
            # is a client-only mirror of a model defined elsewhere (and Zeitwerk
            # ignores the mirror), this loads the REAL model instead of
            # re-opening it with a mismatched superclass. Classic apps where the
            # public file IS the model still autoload it the same way. Only if
            # the constant cannot be autoloaded do we require the file itself.
            model =
              begin
                class_path.camelize.constantize
              rescue NameError, LoadError
                begin
                  require_dependency(file)
                  class_path.camelize.constantize
                rescue NameError, LoadError
                  nil
                end
              end
            next unless model.is_a?(Class) && model < ActiveRecord::Base
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
