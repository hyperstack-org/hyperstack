require 'opal'
require 'react/react-source'
require 'hyper-react'
require 'hyper-store'
if React::IsomorphicHelpers.on_opal_client?
  require 'opal-jquery'
  require 'browser/delay'
end

class HyperOperation
  class << self
    def on_dispatch(&block)
      receivers << block
    end

    def receivers
      @receivers ||= []
    end

    def dispatch(params = {})
      receivers.each do |receiver|
        receiver.call params
      end
    end
  end

  def dispatch(params = {})
    self.class.receivers.each do |receiver|
      receiver.call params
    end
  end
end

module HyperLoop
  class Boot < HyperOperation
    include React::IsomorphicHelpers

    before_first_mount do
      dispatch
    end
  end
end

require_tree './components'