class UsingState < HyperComponent
  # Our component has two instance variables to keep track of what is going on
  #   @show        - if true we will show an input box, otherwise the box is hidden
  #   @input_value - tracks what the user is typing into the input box.
  # We use the mutate method to signal all observers when the state changes.

  render(DIV) do
    # the button method returns an HTML element
    # .on(:click) is an event handeler
    button.on(:click) { mutate @show = !@show }
    DIV do
      input
      output
      easter_egg
    end if @show
  end

  def button
    BUTTON(class: 'ui primary button') { @show ? 'Hide' : 'Show' }
  end

  def input
    DIV(class: 'ui input fluid block') do
      INPUT(type: :text).on(:change) do |evt|
        # we are updating the value per keypress
        mutate @input_value = evt.target.value
      end
    end
  end

  def output
    # this will re-render whenever input_value changes
    P { "#{@input_value}" }
  end

  def easter_egg
    H2 {'you found it!'} if @input_value == 'egg'
  end
end
