require 'bundler'
Bundler.require

require "opal/rspec"
require "opal-jquery"

begin
  require "react-rails"
rescue NameError
end

if Opal::RSpec.const_defined?("SprocketsEnvironment")
  sprockets_env = Opal::RSpec::SprocketsEnvironment.new
  sprockets_env.cache = Sprockets::Cache::FileStore.new("tmp")
  sprockets_env.add_spec_paths_to_sprockets
  run Opal::Server.new(sprockets: sprockets_env) { |s|
    s.main = 'opal/rspec/sprockets_runner'
    s.append_path React::Rails::AssetVariant.new(addons: true).react_directory
    s.debug = false
    s.append_path 'spec/vendor'
    s.index_path = 'spec/index.html.erb'
  }
else
  run Opal::Server.new { |s|
    s.main = 'opal/rspec/sprockets_runner'
    s.append_path React::Rails::AssetVariant.new(addons: true).react_directory
    s.append_path 'spec'
    s.append_path 'spec/vendor'
    s.debug = false
    s.index_path = 'spec/index.html.erb'
  }
end
