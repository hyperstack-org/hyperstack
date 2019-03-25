module Hyperloop
  module Console
    module Rails
      class Engine < ::Rails::Engine
        initializer "static assets" do |app|
          app.middleware.use ::ActionDispatch::Static, "#{root}/public"
        end
      end
    end
  end
end
