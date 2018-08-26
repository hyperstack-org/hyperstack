module HyperRecord
  module Mixin
    def self.included(base)
      if RUBY_ENGINE == 'opal'
        base.extend(HyperRecord::ClientClassMethods)
        base.extend(HyperRecord::ClientClassProcessor)
        base.include(HyperRecord::ClientInstanceMethods)
        base.include(HyperRecord::ClientInstanceProcessor)
        base.class_eval do
          scope :all
        end
      else
        base.extend(HyperRecord::ServerClassMethods)
        base.include(HyperRecord::ServerInstanceMethods)
      end
    end
  end
end