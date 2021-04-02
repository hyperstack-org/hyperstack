module ActiveRecord
  # client side ActiveRecord::Base proxy
  class Base
    include InstanceMethods
    extend  ClassMethods

    scope :limit, ->() {}
    scope :offset, ->() {}

    finder_method :__hyperstack_internal_scoped_last
    scope :__hyperstack_internal_scoped_last_n, ->(n) { last(n) }

    def self.where(*args)
      if args[0].is_a? Hash
        # we can compute membership in the scope when the arg is a hash
        __hyperstack_internal_where_hash_scope(args[0])
      else
        # otherwise the scope has to always be computed on the server
        __hyperstack_internal_where_sql_scope(*args)
      end
    end

    scope :__hyperstack_internal_where_hash_scope,
          client: ->(attrs) { !attrs.detect { |k, v| self[k] != v } }

    scope :__hyperstack_internal_where_sql_scope

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
