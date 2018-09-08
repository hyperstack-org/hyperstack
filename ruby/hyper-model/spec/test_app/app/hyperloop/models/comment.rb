class Comment < ActiveRecord::Base

  belongs_to :user, optional: true
  belongs_to :todo_item, optional: true

end
