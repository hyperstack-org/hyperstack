require 'rails/generators'

module Rails
  module Generators
    class Base < Thor::Group

      protected

      def add_to_manifest(manifest, &block)
        if File.exists? "app/javascript/packs/#{manifest}"
          append_file "app/javascript/packs/#{manifest}", &block
        else
          create_file "app/javascript/packs/#{manifest}", &block
        end
      end

      def yarn(package, version = nil)
        return if system("yarn add #{package}#{'@' + version if version}")
        raise Thor::Error.new("yarn failed to install #{package} with version #{version}")
      end
    end
  end
end
