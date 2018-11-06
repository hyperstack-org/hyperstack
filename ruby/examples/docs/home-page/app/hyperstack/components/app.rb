class Hyperstack::App < HyperComponent
  render(DIV) do
    hello_world
    hr
    html_dsl_example
    hr
    using_state
  end
end
