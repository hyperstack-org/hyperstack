# app/hyperstack/components/edit_item.rb
class EditItem < HyperComponent
  param :todo
  fires :save
  fires :cancel
  other :etc
  after_mount { jQ[dom_node].focus }
  render do
    INPUT(@Etc, placeholder: 'What is left to do today?',
                defaultValue: @Todo.title, key: @Todo)
    .on(:enter) do |evt|
      @Todo.update(title: evt.target.value)
      saved!
    end
    .on(:blur) { cancel! }
  end
end
