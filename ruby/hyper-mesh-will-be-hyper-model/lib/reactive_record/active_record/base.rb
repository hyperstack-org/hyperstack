module ActiveRecord
  # client side ActiveRecord::Base proxy
  class Base
    include InstanceMethods
    extend  ClassMethods

    scope :limit, ->() {}
    scope :offset, ->() {}
  end
end
