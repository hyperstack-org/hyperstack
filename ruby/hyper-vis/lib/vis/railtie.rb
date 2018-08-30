module Vis
  class Railtie < Rails::Railtie
    initializer "vis_asset_paths" do
      Rails.configuration.assets.paths.prepend Pathname.new(__dir__).join('source')
    end
  end
end