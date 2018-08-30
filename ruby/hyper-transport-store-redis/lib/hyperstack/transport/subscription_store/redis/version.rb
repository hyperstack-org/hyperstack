module Hyperstack
  module Transport
    module SubscriptionStore
      class Redis
        VERSION = File.read(File.expand_path("../../../../../../../HYPERSTACK_VERSION", __dir__)).strip
      end
    end
  end
end
