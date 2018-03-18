if RUBY_ENGINE != 'opal'
  module Hyperloop
    define_setting(:resource_api_base_path, '/api')
    define_setting(:resource_transport, :pusher)
    define_setting(:pusher, {})
  end
else
  module Hyperloop
    def self.current_user_id
      HyperRecord::ClientDrivers.opts[:current_user_id]
    end
  end
end