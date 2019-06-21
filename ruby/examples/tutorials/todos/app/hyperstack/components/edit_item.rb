# app/hyperstack/components/edit_item.rb
class EditItem < HyperComponent
  param :todo
  fires :saved
  fires :cancel
  other :etc
  after_mount { jQ[dom_node].focus }
  render do
    INPUT(etc, placeholder: 'What is left to do today?',
                defaultValue: todo.title, key: todo)
    .on(:enter) do |evt|
      todo.update(title: evt.target.value)
      saved!
    end
    .on(:blur) { cancel! }
  end
end
