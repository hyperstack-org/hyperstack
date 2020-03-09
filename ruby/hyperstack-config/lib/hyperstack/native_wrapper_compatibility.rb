# allows hyperstack to include Native::Wrapper even if running Opal 0.11
module Native
  module Wrapper
    def self.included(klass)
      if defined? Native::Helpers
        klass.extend Native::Helpers
      else
        klass.include Native
      end
    end
  end
end
