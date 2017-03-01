require_relative 'router/class_methods'
require_relative 'router/component_methods'

module Hyperloop
  class Router
    def self.inherited(child)
      child.include(React::Component)
      child.include(Base)
    end
  end

  class BrowserRouter
    def self.inherited(child)
      child.include(React::Component)
      child.include(Router::Browser)
    end
  end

  class HashRouter
    def self.inherited(child)
      child.include(React::Component)
      child.include(Router::Hash)
    end
  end

  class MemoryRouter
    def self.inherited(child)
      child.include(React::Component)
      child.include(Router::Memory)
    end
  end

  class StaticRouter
    def self.inherited(child)
      child.include(React::Component)
      child.include(Router::Static)
    end
  end
end
