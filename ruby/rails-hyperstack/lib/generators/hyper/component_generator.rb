require 'rails/generators'
module Hyper
  class Component < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    argument :components, type: :array
    def create_component_file
      self.components.each do |component|
        component_array = component.split('::')
        @modules = component_array[0..-2]
        @file_name = component_array.last
        @indent = 0
        template 'component_template.rb',
                 File.join('app/hyperloop/components',
                           @modules.map(&:downcase).join('/'),
                           "#{@file_name.underscore}.rb")
      end
    end
  end
end
