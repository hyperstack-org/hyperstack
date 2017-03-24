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

    alias_native :block
    alias_native :create_href, :createHref
    alias_native :go
    alias_native :go_back, :goBack
    alias_native :go_forward, :goForward
    alias_native :push, :push
    alias_native :replace, :replace
  end
end
