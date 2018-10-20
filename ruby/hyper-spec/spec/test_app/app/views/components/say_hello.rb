class SayHello
  include Hyperstack::Component
  param :name
  render(DIV) do
    "Hello there #{params.name}"
  end
end
