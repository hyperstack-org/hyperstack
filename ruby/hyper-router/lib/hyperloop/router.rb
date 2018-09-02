module Hyperloop
  class Router
    def self.inherited(child)
      child.include(Hyperloop::Component::Mixin)
      child.include(Base)
    end
  end

  class BrowserRouter
    def self.inherited(child)
      child.include(Hyperloop::Component::Mixin)
      child.include(Hyperloop::Router::Browser)
    end
  end

  class HashRouter
    def self.inherited(child)
      child.include(Hyperloop::Component::Mixin)
      child.include(Hyperloop::Router::Hash)
    end
  end

  class MemoryRouter
    def self.inherited(child)
      child.include(Hyperloop::Component::Mixin)
      child.include(Hyperloop::Router::Memory)
    end
  end

  class StaticRouter
    def self.inherited(child)
      child.include(Hyperloop::Component::Mixin)
      child.include(Hyperloop::Router::Static)
    end
  end
end
