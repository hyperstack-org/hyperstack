require 'rails/generators'

module Rails
  module Generators
    class Base < Thor::Group

      protected

      def warnings
        @warnings ||= []
      end

      def create_component_file(template)
        clear_cache
        insure_hyperstack_loader_installed
        check_javascript_link_directory
        added = webpack_check
        insure_base_component_class_exists
        @no_help = options.key?('no-help')
        self.components.each do |component|
          component_array = component.split('::')
          @modules = component_array[0..-2]
          @file_name = component_array.last
          @indent = 0
          template template,
                   Rails.root.join('app', 'hyperstack', 'components',
                             *@modules.map(&:downcase),
                             "#{@file_name.underscore}.rb")
        end
        add_route
        return unless added

        say '📦 Webpack integrated with Hyperstack.  '\
            'Add javascript assets to app/javascript/packs/client_only.js and /client_and_server.js 📦', :green
      end


      def clear_cache
        run 'rm -rf tmp/cache' unless Dir.exist?(Rails.root.join('app', 'hyperstack'))
      end

      def insure_hyperstack_loader_installed
        hyperstack_loader = %r{//=\s+require\s+hyperstack-loader\s+}
        application_js = Rails.root.join(
          'app', 'assets', 'javascripts', 'application.js'
        )
        if File.exist? application_js
          unless File.foreach(application_js).any? { |l| l =~ hyperstack_loader }
            require_tree = %r{//=\s+require_tree\s+}
            if File.foreach(application_js).any? { |l| l =~ require_tree }
              inject_into_file 'app/assets/javascripts/application.js', verbose: false, before: require_tree do
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
          Dir.glob(Rails.root.join('app', 'views', '**', '*.erb')) do |file|
            if File.foreach(file).any? { |l| l =~ application_pack_tag }
              inject_into_file file, verbose: false, after: application_pack_tag do
                "\n    <%= javascript_include_tag 'application' %>"
              end
            end
          end
        end
      end

      def check_javascript_link_directory
        manifest_js_file = Rails.root.join("app", "assets", "config", "manifest.js")
        return unless File.exist? manifest_js_file
        return unless File.readlines(manifest_js_file).grep(/javascripts \.js/).empty?

        append_file manifest_js_file, "//= link_directory ../javascripts .js\n", verbose: false
      end

      def insure_base_component_class_exists
        @component_base_class = options['base-class'] || Hyperstack.component_base_class
        file_name = Rails.root.join(
          'app', 'hyperstack', 'components', "#{@component_base_class.underscore}.rb"
        )
        template 'hyper_component_template.rb', file_name unless File.exist? file_name
      end

      def add_to_manifest(manifest, &block)
        if File.exist? "app/javascript/packs/#{manifest}"
          append_file "app/javascript/packs/#{manifest}", verbose: false, &block
        else
          create_file "app/javascript/packs/#{manifest}", verbose: false, &block
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

      def install_webpack
        insure_yarn_loaded
        add_webpacker_manifests
        add_webpacks
        cancel_react_source_import
        install_webpacker
      end

      def inject_into_initializer(s)
        file_name = Rails.root.join('config', 'initializers', 'hyperstack.rb')
        if File.exist?(file_name)
          prepend_to_file(file_name, verbose: false) { "#{s}\n" }
        else
          create_file file_name, <<-RUBY
#{s}

# server_side_auto_require will patch the ActiveSupport Dependencies module
# so that you can define classes and modules with files in both the
# app/hyperstack/xxx and app/xxx directories.  For example you can split
# a Todo model into server and client related definitions and place this
# in `app/hyperstack/models/todo.rb`, and place any server only definitions in
# `app/models/todo.rb`.

require "hyperstack/server_side_auto_require.rb"

# set the component base class

Hyperstack.component_base_class = 'HyperComponent' # i.e. 'ApplicationComponent'

# prerendering is default :off, you should wait until your
# application is relatively well debugged before turning on.

Hyperstack.prerendering = :off # or :on

# add this line if you need jQuery AND ARE NOT USING WEBPACK
# Hyperstack.import 'hyperstack/component/jquery', client_only: true

# change definition of on_error to control how errors such as validation
# exceptions are reported on the server
module Hyperstack
  def self.on_error(operation, err, params, formatted_error_message)
    ::Rails.logger.debug(
      "\#{formatted_error_message}\\n\\n" +
      Pastel.new.red(
        'To further investigate you may want to add a debugging '\\
        'breakpoint to the on_error method in config/initializers/hyperstack.rb'
      )
    )
  end
end if Rails.env.development?
          RUBY
        end
        # whenever we modify the initializer its best to empty the cache, BUT
        # we only need to it once per generator execution
        run 'rm -rf tmp/cache' unless @cache_emptied_already
        @cache_emptied_already = true
      end

      private

      def webpack_check
        return unless defined? ::Webpacker

        client_and_server = Rails.root.join("app", "javascript", "packs", "client_only.js")
        return if File.exist? client_and_server

        # Dir.chdir(Rails.root.join.to_s) { run 'bundle exec rails hyperstack:install:webpack' }

        # say "warning: you are running webpacker, but the hyperstack webpack files have not been created.\n"\
        #     "         Suggest you run bundle exec rails hyperstack:install:webpack soon.\n"\
        #     "         Or to avoid this warning create an empty file named app/javascript/packs/client_only.js",
        #     :red
        install_webpack
        true
      end

      def insure_yarn_loaded
        begin
          yarn_version = `yarn --version`
          raise Errno::ENOENT if yarn_version.blank?
        rescue Errno::ENOENT
          raise Thor::Error.new("please insure nodejs is installed and the yarn command is available if using webpacker")
        end
      end

      def add_webpacker_manifests
        create_file 'app/javascript/packs/client_and_server.js', <<-JAVASCRIPT
//app/javascript/packs/client_and_server.js
// these packages will be loaded both during prerendering and on the client
React = require('react');                         // react-js library
createReactClass = require('create-react-class'); // backwards compatibility with ECMA5
History = require('history');                     // react-router history library
ReactRouter = require('react-router');            // react-router js library
ReactRouterDOM = require('react-router-dom');     // react-router DOM interface
ReactRailsUJS = require('react_ujs');             // interface to react-rails
// to add additional NPM packages run `yarn add package-name@version`
// then add the require here.
        JAVASCRIPT
        create_file 'app/javascript/packs/client_only.js', <<-JAVASCRIPT
//app/javascript/packs/client_only.js
// add any requires for packages that will run client side only
ReactDOM = require('react-dom');               // react-js client side code
jQuery = require('jquery');                    // remove if you don't need jQuery
// to add additional NPM packages call run yarn add package-name@version
// then add the require here.
        JAVASCRIPT
        append_file 'config/initializers/assets.rb', verbose: false do
          <<-RUBY
  Rails.application.config.assets.paths << Rails.root.join('public', 'packs', 'js').to_s
          RUBY
        end
        inject_into_file 'config/environments/test.rb', verbose: false, before: /^end/ do
          <<-RUBY

  # added by hyperstack installer
  config.assets.paths << Rails.root.join('public', 'packs-test', 'js').to_s
          RUBY
        end
      end

      def add_webpacks
        yarn 'react', '16'
        yarn 'react-dom', '16'
        yarn 'react-router', '^5.0.0'
        yarn 'react-router-dom', '^5.0.0'
        yarn 'react_ujs', '^2.5.0'
        yarn 'jquery', '^3.4.1'
        yarn 'create-react-class'
      end

      def cancel_react_source_import
        inject_into_initializer(
          "# Hyperstack.import 'react/react-source-browser' "\
          "# uncomment this line if you want hyperstack to use its copy of react"
        )
      end

      def install_webpacker
        return if defined?(::Webpacker)

        gem "webpacker"
        Bundler.with_unbundled_env do
          run "bundle install"
        end
        `spring stop`
        Dir.chdir(Rails.root.join.to_s) { run 'bundle exec rails webpacker:install' }
      end
    end
  end
end
