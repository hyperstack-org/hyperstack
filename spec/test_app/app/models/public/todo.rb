class Todo < ActiveRecord::Base
  # see spec/examples folder for typically setup
  belongs_to :owner, class_name: "User"
  belongs_to :created_by, class_name: "User"
  has_many :comments
end
