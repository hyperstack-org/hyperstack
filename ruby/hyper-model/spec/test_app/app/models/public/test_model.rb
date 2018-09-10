class TestModel < ActiveRecord::Base
  has_many :child_models
  scope :completed, -> () { where(completed: true)  }
  scope :active,    -> () { where(completed: false) }
end
