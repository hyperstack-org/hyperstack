module Hyperstack
  module Model
    def self.load(&block)
      ReactiveRecord.load(&block)
    end
  end
end
