class Comment < ActiveRecord::Base
  
  def create_permitted?  
    # for testing we allow anything if there is no acting_user
    # in the real world you would have something like this:
    # acting_user and (acting_user.admin? or user_is? acting_user)
    !acting_user or user_is? acting_user
  end
  
  def destroy_permitted?
    !acting_user or user_is? acting_user
  end

  belongs_to :user
  belongs_to :todo_item
  
  has_one :todo, -> {}, class_name: "TodoItem"  # this is just so we can test scopes params and null belongs_to relations

end