if RUBY_ENGINE == 'opal'
  # nothing
else
  require 'hyperstack/transport/subscription_store/redis/version'
  require 'hyperstack/transport/subscription_store/redis/config'
  require 'hyperstack/transport/subscription_store/redis'
end