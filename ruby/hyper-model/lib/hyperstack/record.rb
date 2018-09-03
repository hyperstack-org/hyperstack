module Hyperstack::Record
  # keep this for autoloader happiness
end

if RUBY_ENGINE == 'opal'
  require 'hyperstack/record/dummy_value'
  require 'hyperstack/record/collection'
  require 'hyperstack/record/client_class_methods'
  require 'hyperstack/record/client_class_processor'
  require 'hyperstack/record/client_instance_methods'
  require 'hyperstack/record/client_instance_processor'
  require 'hyperstack/record/mixin'
  require 'hyperstack/record/base'
else
  require 'hyperstack/record/server_class_methods'
  require 'hyperstack/record/server_instance_methods'
  require 'hyperstack/record/mixin'
  require 'hyperstack/record/base'
end
