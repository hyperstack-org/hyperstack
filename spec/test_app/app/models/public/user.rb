class User < ActiveRecord::Base
  # see spec/examples folder for typically setup
  has_many :assigned_todos, class_name: "Todo", foreign_key: :owner_id
  has_many :authored_todos, class_name: "Todo", foreign_key: :created_by_id
  has_many :comments, foreign_key: :author_id
  belongs_to :manager, class_name: "User"
  has_many :employees, class_name: "User", foreign_key: :manager_id
end
