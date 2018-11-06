class UsingState < HyperComponent
  # Our component has two instance variables to keep track of what is going on
  #   @show        - if true we will show an input box, otherwise the box is hidden
  #   @input_value - tracks what the user is typing into the input box.
  # We use the mutate method to signal all observers when the state changes.

  render(DIV) do
    # the button method returns an HTML element
    # .on(:click) is an event handeler
    hide_or_show_button.on(:click) { mutate @show = !@show }
    div do
      input_div
      output
      easter_egg
    end if @show
  end

  def hide_or_show_button
    button(class: 'ui primary button') { @show ? 'Hide' : 'Show' }
  end

  def input_div
    div(class: 'ui input fluid block') do
      input(type: :text).on(:change) do |evt|
        # we are updating the value per keypress
        mutate @input_value = evt.target.value
      end
    end
  end

  def output
    # this will re-render whenever input_value changes
    para { "#{@input_value}" }
  end

  def easter_egg
    h2 {'you found it!'} if @input_value == 'egg'
  end
end
