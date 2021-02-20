module Components
  class HelloWorld
    include Hyperstack::Component

    render do
      DIV do
        "Hello, World!".span
      end
    end
  end
end
