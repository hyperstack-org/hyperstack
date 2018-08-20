if RUBY_ENGINE != 'opal'
  module Hyperstack

    # available settings
    class << self
      attr_accessor :api_path
      attr_accessor :valid_business_class_names
    end

    self.add_client_options(%i[api_path])

    # default values
    self.valid_business_class_names = []
  end
end