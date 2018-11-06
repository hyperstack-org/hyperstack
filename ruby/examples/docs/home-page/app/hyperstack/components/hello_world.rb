class HelloWorld < HyperComponent
  render(DIV) do
    # try changing 'world' to your own name
    h1 { 'Hello world' }
    para(class: 'green-text') { "Let's gets started!" }
  end
end
