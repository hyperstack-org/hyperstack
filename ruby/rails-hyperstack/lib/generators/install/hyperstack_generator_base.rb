require 'rails/generators'

module Rails
  module Generators
    class Base < Thor::Group

      protected

      def warnings
        @warnings ||= []
      end

      def clear_cache
        run 'rm -rf tmp/cache' unless Dir.exists?(File.join('app', 'hyperstack'))
      end

      def insure_hyperstack_loader_installed
        hyperstack_loader = %r{//=\s+require\s+hyperstack-loader\s+}
        application_js = File.join(
          'app', 'assets', 'javascripts', 'application.js'
        )
        if File.exist? application_js
          unless File.foreach(application_js).any? { |l| l =~ hyperstack_loader }
            require_tree = %r{//=\s+require_tree\s+}
            if File.foreach(application_js).any? { |l| l =~ require_tree }
              inject_into_file 'app/assets/javascripts/application.js', before: require_tree do
                "//= require hyperstack-loader\n"
              end
            else
              warnings <<
                " ***********************************************************\n"\
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
        else
          create_file application_js, "//= require hyperstack-loader\n"
          warnings <<
            " ***********************************************************\n"\
            " * Could not find the  app/assets/application.js file.     *\n"\
            " * We created one for you, and added the                   *\n"\
            " * `<%= javascript_include_tag 'application' %>` to your   *\n"\
            " * `html.erb` files immediately after any                  *\n"\
            " * `<%= javascript_pack 'application' %>` tags we found.   *\n"\
            " ***********************************************************\n"
          application_pack_tag =
            /\s*\<\%\=\s+javascript_pack_tag\s+(\'|\")application(\'|\").*\%\>.*$/
          Dir.glob(File.join('app', 'views', '**', '*.erb')) do |file|
            if File.foreach(file).any? { |l| l =~ application_pack_tag }
              inject_into_file file, after: application_pack_tag do
                "\n    <%= javascript_include_tag 'application' %>"
              end
            end
          end
        end
      end

      def insure_base_component_class_exists
        @component_base_class = options['base-class']
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
          warnings <<
               " ***********************************************************\n"\
               " * The add-route option ignored because more than one      *\n"\
               " * component is being generated.                           *\n"\
               " ***********************************************************\n"
          return
        end
        action_name = (@modules+[@file_name.underscore]).join('__')
        path = options['add-route'] == 'add-route' ? '/(*others)' : options['add-route']
        route "get '#{path}', to: 'hyperstack##{action_name}'"
      end


      def yarn(package, version = nil)
        return if system("yarn add #{package}#{'@' + version if version}")
        raise Thor::Error.new("yarn failed to install #{package} with version #{version}")
      end
    end
  end
end
