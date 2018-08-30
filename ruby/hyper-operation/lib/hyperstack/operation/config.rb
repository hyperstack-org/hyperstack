if RUBY_ENGINE != 'opal'
  module Hyperstack

    # available settings
    class << self
      attr_accessor :business_use_authorization
      attr_accessor :valid_business_class_names
    end

    # default values
    self.business_use_authorization = true
    self.valid_business_class_names = []
  end
end