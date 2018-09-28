class SayHello
  include Hyperstack::Component::Mixin
  param :name
  render(DIV) do
    "Hello there #{params.name}"
  end
end
