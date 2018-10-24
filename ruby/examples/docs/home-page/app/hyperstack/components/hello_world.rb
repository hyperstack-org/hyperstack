class HelloWorld < HyperComponent
  render(DIV) do
    # try changing 'world' to your own name
    H1 { 'Hello world' }
    P(class: 'green-text') { "Let's gets started!" }
  end
end
