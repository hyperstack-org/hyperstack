if RUBY_ENGINE == 'opal'
  require 'hyper_record/dummy_value'
  require 'hyper_record/collection'
  require 'hyper_record/class_methods'
  require 'hyper_record/client_instance_methods'
end

module HyperRecord
  if RUBY_ENGINE == 'opal'
    def self.included(base)
      base.include(Hyperloop::Store::Mixin)
      base.extend(HyperRecord::ClassMethods)
      base.include(HyperRecord::ClientInstanceMethods)
      base.class_eval do
        state :record_state
      end
    end
  end
end
