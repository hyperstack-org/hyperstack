class SayHello < React::Component::Base
  param :name
  render(DIV) do
    "Hello there #{params.name}"
  end
end
