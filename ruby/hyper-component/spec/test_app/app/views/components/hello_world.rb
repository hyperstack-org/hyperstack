module Components
  class HelloWorld
    include Hyperstack::Component::Mixin

    def render
      div do
        "Hello, World!".span
      end
    end
  end
end
