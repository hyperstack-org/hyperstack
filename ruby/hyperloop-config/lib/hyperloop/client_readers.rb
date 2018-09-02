module Hyperloop
# configuration utility
  class << self
    def client_readers
      @client_readers ||= []
    end

    def client_reader_hash
      @client_readers_hash ||= {}
    end

    def client_reader(*args)
      # configuration.client_reader[:foo] = 12  initialize your own client value
      # configuration.client_reader :foo, :bar  make previous setting readable on client
      client_readers += [*args]
      client_reader_hash
    end
  end
end
