module ActiveRecord
  # client side ActiveRecord::Base proxy
  class Base
    include InstanceMethods
    extend  ClassMethods

    scope :limit, ->() {}
    scope :offset, ->() {}

    finder_method :__hyperstack_internal_scoped_last
    scope :__hyperstack_internal_scoped_last_n, ->(n) { last(n) }

    ReactiveRecord::ScopeDescription.new(
      self, :___hyperstack_internal_scoped_find_by,
      client: ->(attrs) { !attrs.detect { |attr, value| attributes[attr] != value } }
    )

    def self.__hyperstack_internal_scoped_find_by(attrs)
      collection = all.apply_scope(:___hyperstack_internal_scoped_find_by, attrs).observed
      if !collection.collection
        collection._find_by_initializer(self, attrs)
      else
        collection.first
      end
    end
  end
end
