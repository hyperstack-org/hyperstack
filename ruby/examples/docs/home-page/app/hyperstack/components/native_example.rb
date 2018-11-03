class JSExamples < HyperComponent
  render(DIV) do
    # Notice how Components are composed of Components
    MyModal()
    Sem.Divider(hidden: true) # Sem is a JS library
    SelectDate()
  end
end

class MyModal < HyperComponent
  render(DIV) do
    # Sem is Semnatic UI React (imported)
    # type 'Sem.' on your JavaScript console...
    button = Sem.Button { 'Open Modal' }.as_node
    Sem.Modal(trigger: button.to_n) do
      Sem.ModalHeader { 'Heading' }
      Sem.ModalContent { 'Content' }
    end
  end
end

class SelectDate < HyperComponent
  before_mount do
    # before_mount will run only once
    # moment is a JS function so we use ``
    mutate.date `moment()`
  end

  render(DIV) do
    # DatePicker is a JS Component imported with Webpack
    # Notice the lambda to pass a Ruby method as a callback
    DatePicker(selected: @date,
               todayButton: "Today",
               onChange: ->(date) { mutate @date = date }
    )
    # see how we use `` and #{} to b ridger JS and Ruby
    H3 { `moment(#{@date}).format('LL')` }
    #  or if you prefer..
    # H3 { Native(`moment`).call(state.date).format('LL') }
  end
end
