if RUBY_ENGINE != 'opal'
  module Hyperstack

    # available settings
    class << self
      attr_accessor :resource_use_authorization
      attr_accessor :resource_use_pubsub
      attr_accessor :valid_record_class_params
    end

    # default values
    self.valid_record_class_params = []
    self.resource_use_authorization = true
    self.resource_use_pubsub = true
  end
end