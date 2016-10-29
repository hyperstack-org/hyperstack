class AddSingleCommentToTodoItem < ActiveRecord::Migration
  def change
    add_column :todo_items, :comment_id, :integer
  end
end
