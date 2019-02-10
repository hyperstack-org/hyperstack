module ActiveRecord
  # client side ActiveRecord::Base proxy
  class Base
    include InstanceMethods
    extend  ClassMethods

    scope :limit, ->() {}
    scope :offset, ->() {}

    ReactiveRecord::ScopeDescription.new(
      self, :___hyperstack_internal_scoped_find_by,
      client: ->(attrs) {
        puts "evaluating find_by(#{attrs}) with #{inspect} #{attributes}"
        (!attrs.detect { |attr, value| attributes[attr] != value }).tap { |result| puts "returning #{!!result}"}
      }
    )

    def self.__hyperstack_internal_scoped_find_by(attrs)
      collection = all.apply_scope(:___hyperstack_internal_scoped_find_by, attrs)
      if !collection.collection
        collection._find_by_initializer(self, attrs)
      else
        collection.first
      end
    end
  end
end
