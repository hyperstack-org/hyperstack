module Hyperloop
  define_setting :public_model_directories, [File.join('app','hyperloop','models'), File.join('app','models','public')]
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
        # begin
        #   @public_columns_hash[model.name] = model.columns_hash if model.table_name
        # rescue Exception => e
        #   binding.pry
        #   @public_columns_hash = nil
        #   raise $!, "Could not read 'columns_hash' for #{model}: #{$!}", $!.backtrace
        # end if files.include?(model.name.underscore) && model.name.underscore != 'application_record'
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
