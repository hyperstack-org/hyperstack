module Hyperstack
  module Record
    module Mixin
      def self.included(base)
        if RUBY_ENGINE == 'opal'
          base.extend(Hyperstack::Record::ClientClassMethods)
          base.extend(Hyperstack::Record::ClientClassProcessor)
          base.include(Hyperstack::Record::ClientInstanceMethods)
          base.include(Hyperstack::Record::ClientInstanceProcessor)
          base.class_eval do
            scope :all
          end
        else
          base.extend(Hyperstack::Record::ServerClassMethods)
          base.include(Hyperstack::Record::ServerInstanceMethods)
        end
      end
    end
  end
end