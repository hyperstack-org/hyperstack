module Hyper
  class Component < GeneratorBase
    def add_component
      create_component_file 'component_template.rb'
    end
  end
end
