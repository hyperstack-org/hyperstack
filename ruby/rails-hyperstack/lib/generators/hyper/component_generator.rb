require 'rails/generators'
module Hyper
  class Component < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)
    argument :components, type: :array
    class_option 'base-class', :default => 'HyperComponent'
    class_option 'add-route', :default => nil

    def create_component_file
      clear_cache
      insure_hyperstack_loader_installed
      insure_base_component_class_exists unless options['base-class'] == 'skip'
      self.components.each do |component|
        component_array = component.split('::')
        @modules = component_array[0..-2]
        @file_name = component_array.last
        @indent = 0
        template 'component_template.rb',
                 File.join('app', 'hyperstack', 'components',
                           *@modules.map(&:downcase),
                           "#{@file_name.underscore}.rb")
      end
      add_route
    end
  end
end
