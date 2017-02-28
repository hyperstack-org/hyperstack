class InputWord < React::Component::Base
  param :label
  param :button
  param :operation
  render(DIV) do
    LABEL { params.label }
    INPUT(class: :word)
    BUTTON { params.button }.on(:click) do
      params.operation.run(word: Element[dom_node].find('.word').value)
      .fail { |e| alert e.message }
    end
  end
end
