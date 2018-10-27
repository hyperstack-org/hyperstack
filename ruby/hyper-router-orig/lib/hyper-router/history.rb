module HyperRouter
  class History
    include Native

    def initialize(native)
      @native = native
    end

    def to_n
      @native
    end

    def location
      HyperRouter::Location.new(`#{@native}.location`)
    end

    def block(message = nil)
      if message
        native_block(message.to_n)
      else
        native_block do |location, action|
          yield Location.new(location), action
        end
      end
    end

    def listen
      native_listen do |location, action|
        yield Location.new(location), action
      end
    end

    alias_native :action
    alias_native :native_block, :block
    alias_native :create_href, :createHref
    alias_native :entries
    alias_native :go
    alias_native :go_back, :goBack
    alias_native :go_forward, :goForward
    alias_native :index
    alias_native :length
    alias_native :native_listen, :listen
    alias_native :push, :push
    alias_native :replace, :replace
  end
end
