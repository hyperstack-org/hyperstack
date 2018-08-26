module HyperRecord
  # keep this for autoloader happiness
end

if RUBY_ENGINE == 'opal'
  require 'hyper_record/dummy_value'
  require 'hyper_record/collection'
  require 'hyper_record/transducer'
  require 'hyper_record/client_class_methods'
  require 'hyper_record/client_class_processor'
  require 'hyper_record/client_instance_methods'
  require 'hyper_record/client_instance_processor'
  require 'hyper_record/mixin'
  require 'hyper_record/base'
else
  require 'hyper_record/server_class_methods'
  require 'hyper_record/server_instance_methods'
  require 'hyper_record/mixin'
  require 'hyper_record/base'
end


