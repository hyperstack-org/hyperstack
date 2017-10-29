module Hyperloop
  define_setting :public_model_directories, ['app/hyperloop/models']
end

module ActiveRecord
  # adds method to get the HyperMesh public column types
  # this works because the public folder is currently required to be eager loaded.
  class Base
    def self.public_columns_hash
      return @public_columns_hash if @public_columns_hash && Rails.env.production?
      files = []
      Hyperloop.public_model_directories.each do |dir|
        dir_length = Rails.root.join(dir).to_s.length + 1
        Dir.glob(Rails.root.join(dir, '**', '*.rb')).each do |file|
          require_dependency(file)
          files << file[dir_length..-4]
        end
      end
      @public_columns_hash = {}
      # descendants only works for already loaded models!
      # in production they are eager loaded -> no problem
      # in development this hash is always recreated, the model is loaded when its first used,
      # probably elsewhere, before this method is called, otherwise a page reload is needed
      # TODO: investigate, make sure all public models are loaded or info for all models is included.
      descendants.each do |model|
        if files.include?(model.name.underscore) && model != ApplicationRecord
          @public_columns_hash[model.name] = model.columns_hash rescue nil # why rescue?
        end
      end
      @public_columns_hash
    end

    def self.public_columns_hash_as_json
      return @public_columns_hash_json if @public_columns_hash_json && Rails.env.production?
      pch = public_columns_hash
      return @public_columns_hash_json if @prev_public_columns_hash == pch
      @prev_public_columns_hash = pch
      @public_columns_hash_json = pch.to_json
    end
  end
end
