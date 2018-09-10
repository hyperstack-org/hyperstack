module Hyperloop
  module Model
    def self.load(&block)
      ReactiveRecord.load(&block)
    end
  end
end
