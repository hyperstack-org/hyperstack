require "native"

module Native
  module Helpers
    def aliases_native(native_names)
      native_names.each do |native_name|
        alias_native(native_name.underscore, native_name)
      end
    end
  end
end
