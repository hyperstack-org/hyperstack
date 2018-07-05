if RUBY_ENGINE == 'opal'
  module Hyperloop
    def self.current_user_id
      Hyperloop::Resource::ClientDrivers.opts[:current_user_id]
    end
  end
else
  module Hyperloop
    define_setting(:pusher, {})
    define_setting(:pusher_instance, nil)
    define_setting(:redis_instance, nil)
    define_setting(:resource_transport, :pusher)
    define_setting(:valid_record_class_params, [])
  end
end