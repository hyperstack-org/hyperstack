module Hyper
  class Router < GeneratorBase
    def add_router_component
      create_component_file 'router_template.rb'
    end
  end
end
