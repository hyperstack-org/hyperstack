require 'rails/generators'
module Hyper
  class Router < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    argument :component, type: :string
    class_option :path, type: :string, default: '/(*other)'
    def create_component_file
      component_array = component.split('::')
      @modules = component_array[0..-2]
      @file_name = component_array.last
      @indent = 0
      template 'router_template.rb',
               File.join('app/hyperloop/components',
                         @modules.map(&:downcase).join('/'),
                         "#{@file_name.underscore}.rb")
    end

    def add_route
      route "get '#{options['path']}', to: 'hyperloop##{@file_name.underscore}'"
    end
  end
end
