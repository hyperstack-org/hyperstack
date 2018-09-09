module Components
  class HelloWorld
    include Hyperloop::Component::Mixin

    def render
      div do
        "Hello, World!".span
      end
    end
  end
end
