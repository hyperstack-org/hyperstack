module ActiveRecord
  # client side ActiveRecord::Base proxy
  class Base
    extend  ClassMethods

    include InstanceMethods

    scope :limit, ->() {}
    scope :offset, ->() {}
  end
end
