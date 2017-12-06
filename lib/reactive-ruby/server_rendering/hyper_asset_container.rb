require 'react/server_rendering/environment_container'
require 'react/server_rendering/manifest_container'
require 'react/server_rendering/webpacker_manifest_container'

module ReactiveRuby
  module ServerRendering
    class HyperAssetContainer
      def initialize
        @ass_containers = []
        if assets_precompiled?
          @ass_containers << React::ServerRendering::ManifestContainer.new if React::ServerRendering::ManifestContainer.compatible?
        else
          @ass_containers << React::ServerRendering::EnvironmentContainer.new if ::Rails.application.assets
        end
        @ass_containers << React::ServerRendering::WebpackerManifestContainer.new if React::ServerRendering::WebpackerManifestContainer.compatible?
      end

      def find_asset(logical_path)
        @ass_containers.each do |ass|
          begin
            asset = ass.find_asset(logical_path)
            return asset if asset
          rescue
            # no asset found, try the next container
          end
        end
        raise "No asset found for #{logical_path}, tried: #{@ass_containers.map { |c| c.class.name }.join(', ')}"
      end

      private

      def assets_precompiled?
        !::Rails.application.config.assets.compile
      end
    end
  end
end