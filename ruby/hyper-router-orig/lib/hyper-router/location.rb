module HyperRouter
  class Location
    include Native

    def initialize(native)
      @native = native
    end

    def to_n
      @native
    end

    def query
      return {} if search.blank?

      Hash[search[1..-1].split('&').map { |part|
        name, value = part.split('=')

        [`decodeURIComponent(#{name})`, `decodeURIComponent(#{value})`]
      }]
    end

    alias_native :pathname
    alias_native :search
    alias_native :hash
    alias_native :state
    alias_native :key
  end
end
