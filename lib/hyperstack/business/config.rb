if RUBY_ENGINE != 'opal'
  module Hyperstack

    # available settings
    class << self
      attr_accessor :valid_business_class_names
    end

    # default values
    self.valid_business_class_names = []
  end
end