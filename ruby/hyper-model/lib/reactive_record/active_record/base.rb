module ActiveRecord
  # client side ActiveRecord::Base proxy
  class Base
    include InstanceMethods
    extend  ClassMethods

    scope :limit, ->() {}
    scope :offset, ->() {}

    finder_method :__hyperstack_internal_scoped_find_by
    def self.___hyperstack_internal_scoped_find_by(attrs)
      attrs.is_a?(Hash) ? find_by(attrs) : find(attrs)
    end
  end
end
