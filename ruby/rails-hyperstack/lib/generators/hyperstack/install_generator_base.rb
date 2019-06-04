require 'rails/generators'

module Rails
  module Generators
    class Base < Thor::Group

      protected

      def create_component_file(template)
        clear_cache
        insure_hyperstack_loader_installed
        insure_base_component_class_exists
        @no_help = options.key?('no-help')
        self.components.each do |component|
          component_array = component.split('::')
          @modules = component_array[0..-2]
          @file_name = component_array.last
          @indent = 0
          template template,
                   File.join('app', 'hyperstack', 'components',
                             *@modules.map(&:downcase),
                             "#{@file_name.underscore}.rb")
        end
        add_route
      end


      def clear_cache
        run 'rm -rf tmp/cache' unless Dir.exists?(File.join('app', 'hyperstack'))
      end

      def insure_hyperstack_loader_installed
        application_js = File.join(
          'app', 'assets', 'javascripts', 'application.js'
        )
        require_tree = %r{//=\s+require_tree\s+}
        hyperstack_loader = %r{//=\s+require\s+hyperstack-loader\s+}
        unless File.foreach(application_js).any? { |l| l =~ hyperstack_loader }
          if File.foreach(application_js).any? { |l| l =~ require_tree }
            inject_into_file 'app/assets/javascripts/application.js', before: require_tree do
              "//= require hyperstack-loader\n"
            end
          else
            puts " ***********************************************************\n"\
                 " * Could not add `//= require hyperstack-loader` directive *\n"\
                 " * to the app/assets/application.js file.                  *\n"\
                 " * Normally this directive is added just before the        *\n"\
                 " * `//= require_tree .` directive at the end of the file,  *\n"\
                 " * but no require_tree directive was found.  You need to   *\n"\
                 " * manually add `//= require hyperstack-loader` to the     *\n"\
                 " * app/assets/application.js file.                         *\n"\
                 " ***********************************************************\n"
          end
        end
      end


      def insure_base_component_class_exists
        @component_base_class = options['base-class'] || Hyperstack.component_base_class
        file_name = File.join(
          'app', 'hyperstack', 'components', "#{@component_base_class.underscore}.rb"
        )
        template 'hyper_component_template.rb', file_name unless File.exists? file_name
      end

      def add_to_manifest(manifest, &block)
        if File.exists? "app/javascript/packs/#{manifest}"
          append_file "app/javascript/packs/#{manifest}", &block
        else
          create_file "app/javascript/packs/#{manifest}", &block
        end
      end

      def add_route
        return unless options['add-route']
        if self.components.count > 1
          puts " ***********************************************************\n"\
               " * The add-route option ignored because more than one      *\n"\
               " * component is being generated.                           *\n"\
               " ***********************************************************\n"
          return
        end
        action_name = (@modules+[@file_name.underscore]).join('__')
        path = options['add-route'] == 'add-route' ? '/(*others)' : options['add-route']
        routing_code = "get '#{path}', to: 'hyperstack##{action_name}'\n"
        log :route, routing_code
        [/mount\s+Hyperstack::Engine[^\n]+\n/m, /\.routes\.draw do\s*\n/m].each do |sentinel|
          in_root do
            inject_into_file 'config/routes.rb', routing_code.indent(2), after: sentinel, verbose: false, force: false
          end
        end
      end

      def yarn(package, version = nil)
        return if system("yarn add #{package}#{'@' + version if version}")
        raise Thor::Error.new("yarn failed to install #{package} with version #{version}")
      end
    end
  end
end
