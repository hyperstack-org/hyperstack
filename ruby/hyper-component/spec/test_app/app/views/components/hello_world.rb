module Components
  class HelloWorld
    include Hyperstack::Component

    def render
      div do
        "Hello, World!".span
      end
    end
  end
end
