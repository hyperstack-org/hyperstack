# allows hyperstack to include Native::Wrapper even if running Opal 0.11
module Native
  module Wrapper
    def self.includedx(klass)
      if Native.instance_methods.include? :to_n
        klass.include Native
      else
        klass.extend Native::Helpers
      end
    end
  end
end
