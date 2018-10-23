module Components
  class HelloWorld
    include Hyperstack::Component

    def render
      DIV do
        "Hello, World!".span
      end
    end
  end
end
