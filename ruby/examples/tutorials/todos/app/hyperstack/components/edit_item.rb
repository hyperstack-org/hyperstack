# app/hyperloop/components/edit_item.rb
class EditItem < HyperComponent
  param    :todo
  triggers :save
  triggers :cancel
  others   :others
  after_mount { DOM[dom_node].focus }
  render do
    INPUT(@Others, defaultValue: @Todo.title, placeholder: 'What is left to do today?',
                   dom: set(:_input), key: @Todo)
    .on(:enter) { @Todo.update(title: @_input.value) and save! }
    .on(:blur)  { cancel! }
  end
end
