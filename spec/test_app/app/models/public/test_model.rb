class TestModel < ActiveRecord::Base
  scope :completed, -> () { where(completed: true)  }
  scope :active,    -> () { where(completed: false) }
end
