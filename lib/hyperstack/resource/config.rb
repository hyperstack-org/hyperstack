if RUBY_ENGINE != 'opal'
  module Hyperstack

    # available settings
    class << self
      attr_accessor :valid_record_class_params
    end

    # default values
    self.valid_record_class_params = []
  end
end