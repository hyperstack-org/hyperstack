if RUBY_ENGINE != 'opal'
  module Hyperstack

    # available settings
    class << self
      attr_accessor :operation_use_authorization
      attr_accessor :valid_operation_class_names
    end

    # default values
    self.operation_use_authorization = true
    self.valid_operation_class_names = []
  end
end