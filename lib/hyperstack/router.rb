module Hyperstack
  class Router
    def self.inherited(child)
      child.include(Hyperstack::Component::Mixin)
      child.include(Base)
    end
  end

  class BrowserRouter
    def self.inherited(child)
      child.include(Hyperstack::Component::Mixin)
      child.include(Hyperstack::Router::Browser)
    end
  end

  class HashRouter
    def self.inherited(child)
      child.include(Hyperstack::Component::Mixin)
      child.include(Hyperstack::Router::Hash)
    end
  end

  class MemoryRouter
    def self.inherited(child)
      child.include(Hyperstack::Component::Mixin)
      child.include(Hyperstack::Router::Memory)
    end
  end

  class StaticRouter
    def self.inherited(child)
      child.include(Hyperstack::Component::Mixin)
      child.include(Hyperstack::Router::Static)
    end
  end
end
