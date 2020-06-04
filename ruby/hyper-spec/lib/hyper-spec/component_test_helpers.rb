# see component_test_helpers_spec.rb for examples
require 'parser/current'
require 'unparser'
require 'hyper-spec/unparser_patch' # not present in original version of refactored hyperspec
require 'method_source'
require 'pry'
require_relative '../../lib/hyper-spec/time_cop.rb'

Parser::Builders::Default.emit_procarg0 = true # not present in original version of refactored hyperspec

module MethodSource
  class << self
    alias original_lines_for_before_hyper_spec lines_for
    alias original_source_helper_before_hyper_spec source_helper

    def source_helper(source_location, name=nil)
      source_location[1] = 1 if source_location[0] == '(pry)'
      original_source_helper_before_hyper_spec source_location, name
    end

    def lines_for(file_name, name = nil)
      if file_name == '(pry)'
        HyperSpec.current_pry_code_block
      else
        original_lines_for_before_hyper_spec file_name, name
      end
    end
  end
end

class Object
  def to_opal_expression
    to_json
  rescue Exception
    to_s
  end
end

class Time
  def to_opal_expression
    "Time.parse('#{inspect}')"
  end
end

class NilClass
  def to_opal_expression
    self.inspect
  end
end

module HyperSpec

  # add a before eval hook to pry so we can capture the source

  if defined? Pry
    class << self
      attr_accessor :current_pry_code_block
      Pry.hooks.add_hook(:before_eval, "hyper_spec_code_capture") do |code|
        HyperSpec.current_pry_code_block = code
      end
    end
  end

  module ComponentTestHelpers
    def self.opal_compile(s)
      Opal.compile(s)
    rescue Exception => e
      puts "puts could not compile: \n\n#{s}\n\n"
      raise e
    end

    def opal_compile(s)
      ComponentTestHelpers.opal_compile(s)
    end

    TOP_LEVEL_COMPONENT_PATCH =
      opal_compile(File.read(File.expand_path('../../sources/top_level_rails_component.rb', __FILE__)))
    TIME_COP_CLIENT_PATCH =
      "#{File.read(File.expand_path('../../sources/lolex.js', __FILE__))}\n" +
      opal_compile(File.read(File.expand_path('../../hyper-spec/time_cop.rb', __FILE__)))


    class << self
      attr_accessor :current_example
      attr_accessor :description_displayed

      def test_id
        @_hyperspec_private_test_id ||= 0
        @_hyperspec_private_test_id += 1
      end

      def display_example_description
        "<script type='text/javascript'>console.log('%c#{current_example.description}'"\
        ",'color:green; font-weight:bold; font-size: 200%')</script>"
      end
    end

    def build_test_url_for(controller, ping = nil)
      unless controller
        unless defined?(::HyperSpecTestController)
          Object.const_set('HyperSpecTestController', Class.new(::ActionController::Base))
        end

        controller = ::HyperSpecTestController
      end

      route_root = controller.name.gsub(/Controller$/, '').underscore

      unless controller.method_defined?(:test)
        controller.class_eval do
          define_method(:test) do
            head(:no_content) && return if params[:id] == 'ping'
            route_root = self.class.name.gsub(/Controller$/, '').underscore
            key = "/#{route_root}/#{params[:id]}"
            test_params = ::Rails.cache.read(key)
            @component_name = test_params[0]
            @component_params = test_params[1]
            html_block = test_params[2]
            render_params = test_params[3]
            render_on = render_params.delete(:render_on) || :client_only
            _mock_time = render_params.delete(:mock_time)
            style_sheet = render_params.delete(:style_sheet)
            javascript = render_params.delete(:javascript)
            code = render_params.delete(:code)
            #page = "#{html_block}\n</body>\n"
            page = "</body>\n"

            page = '<%= react_component @component_name, @component_params, '\
                   "{ prerender: #{render_on != :client_only} } %>\n#{page}" if @component_name
            #page = "<body>\n#{page}"
            unless render_on == :server_only
              page = "<script type='text/javascript'>\n#{TOP_LEVEL_COMPONENT_PATCH}\n</script>\n#{page}" if @component_name
              page = "<script type='text/javascript'>\n#{code}\n</script>\n#{page}" if code
            end

            if render_on != :server_only || Lolex.initialized?
              page = "<script type='text/javascript'>\n#{TIME_COP_CLIENT_PATCH}\n</script>\n#{page}"
            end

            if (render_on != :server_only && !render_params[:layout]) || javascript
              page = "<%= javascript_include_tag '#{javascript || 'application'}' %>\n#{page}"
            end

            if !render_params[:layout] || style_sheet
              page = "<%= stylesheet_link_tag '#{style_sheet || 'application'}' %>\n#{page}"
            end
            page = "<script type='text/javascript'>go = function() "\
                   "{window.hyper_spec_waiting_for_go = false}</script>\n#{page}"

            if ComponentTestHelpers.current_example

              title = view_context.escape_javascript(ComponentTestHelpers.current_example.description)
              title = "#{title}...continued." if ComponentTestHelpers.description_displayed

              page = "<script type='text/javascript'>console.log('%c#{title}',"\
                     "'color:green; font-weight:bold; font-size: 200%')</script>\n#{page}"

              ComponentTestHelpers.description_displayed = true
            end
            page = "<body>\n#{html_block}\n#{page}"
            render_params[:inline] = page
            response.headers['Cache-Control'] = 'max-age=120'
            response.headers['X-Tracking-ID'] = '123456'
            render render_params
          end
        end

        begin
          routes = ::Rails.application.routes
          routes.disable_clear_and_finalize = true
          routes.clear!
          routes.draw do
            get "/#{route_root}/:id", to: "#{route_root}#test"
          end
          ::Rails.application.routes_reloader.paths.each { |path| load(path) }
          routes.finalize!
          ActiveSupport.on_load(:action_controller) { routes.finalize! }
        ensure
          routes.disable_clear_and_finalize = false
        end
      end
      if ping
        "/#{route_root}/ping"
      else
        "/#{route_root}/#{ComponentTestHelpers.test_id}"
      end
    end

    def insert_html(str)
      @_hyperspec_private_html_block = "#{@_hyperspec_private_html_block}\n#{str}"
    end

    def isomorphic(&block)
      yield
      before_mount(&block)
    end

    def evaluate_ruby(p1 = nil, p2 = nil, p3 = nil, &block)
      insure_page_loaded
      # TODO:  better error message here...either you give us a block
      # or first argument must be a hash or a string.
      if p1.is_a? Hash
        str = ''
        p3 = p2
        p2 = p1
      else
        str = p1
      end
      if p3
        opts = p2
        args = p3
      elsif p2
        opts = {}
        args = p2
      else
        opts = args = {}
      end

      args.each do |name, value|
        str = "#{name} = #{value.to_opal_expression}\n#{str}"
      end
      str = add_opal_block(str, block) if block
      js = opal_compile(str).delete("\n").gsub('(Opal);', '(Opal)')
      # workaround for firefox 58 and geckodriver 0.19.1, because firefox is unable to find .$to_json:
      # JSON.parse(evaluate_script("(function(){var a=Opal.Array.$new(); a[0]=#{js}; return a.$to_json();})();"), opts).first
      JSON.parse(evaluate_script("[#{js}].$to_json()"), opts).first
    end

    alias c? evaluate_ruby

    def expect_evaluate_ruby(p1 = nil, p2 = nil, p3 = nil, &block)
      insure_page_loaded
      if p1.is_a? Hash
        str = ''
        p3 = p2
        p2 = p1
      else
        str = p1
      end
      if p3
        opts = p2
        args = p3
      elsif p2
        opts = {}
        args = p2
      else
        opts = args = {}
      end
      args.each do |name, value|
        str = "#{name} = #{value.inspect}\n#{str}"
      end
      expect(evaluate_ruby(add_opal_block(str, block), opts, {}))
    end

    PRIVATE_VARIABLES = %i[
      @__inspect_output @__memoized @example @_hyperspec_private_client_code @_hyperspec_private_html_block @fixture_cache
      @fixture_connections @connection_subscriber @loaded_fixtures @_hyperspec_private_client_options
      b __ _ _ex_ pry_instance _out_ _in_ _dir_ _file_
    ]

    def add_locals(in_str, block)
      b = block.binding

      memoized = b.eval('__memoized').instance_variable_get(:@memoized)
      in_str = memoized.inject(in_str) do |str, pair|
        "#{str}\n#{pair.first} = #{pair.last.to_opal_expression}"
      end if memoized

      in_str = b.local_variables.inject(in_str) do |str, var|
        next str if PRIVATE_VARIABLES.include? var

        "#{str}\n#{var} = #{b.local_variable_get(var).to_opal_expression}"
      end

      in_str = b.eval('instance_variables').inject(in_str) do |str, var|
        next str if PRIVATE_VARIABLES.include? var

        "#{str}\n#{var} = #{b.eval("instance_variable_get('#{var}')").to_opal_expression}"
      end
      in_str
    end

    def find_block(node)
      # find a block with the ast tree.

      return false unless node.class == Parser::AST::Node
      return node if the_node_you_are_looking_for?(node)

      node.children.each do |child|
        found = find_block(child)
        return found if found
      end
      false
    end

    def the_node_you_are_looking_for?(node)
      node.type == :block &&
        node.children.first.class == Parser::AST::Node &&
        node.children.first.type == :send
        # we could also check that the block is going to the right method
        #   respond_to?(node.children.first.children[1]) &&
        #   method(node.children.first.children[1]) == method(:evaluate_ruby)
        # however that does not work for expect { ... }.on_client_to ...
        # because now the block is being sent to expect... so we could
        # check the above OR node.children.first.children[1] == :expect
        # but what if there are two blocks?  on and on...
    end

    def add_opal_block(str, block)
      return str unless block

      source = block.source
      ast = Parser::CurrentRuby.parse(source)
      ast = find_block(ast)
      raise "could not find block within source: #{block.source}" unless ast

      "#{add_locals(str, block)}\n#{Unparser.unparse ast.children.last}"
    end

    def evaluate_promise(str = '', opts = {}, _dummy = nil, &block)
      insure_page_loaded
      str = add_opal_block(str, block)
      str = "(#{str}).then { |args| args = [args]; `window.hyper_spec_promise_result = args` }"
      js = opal_compile(str).gsub("\n","").gsub("(Opal);","(Opal)")
      page.evaluate_script("window.hyper_spec_promise_result = false")
      page.execute_script(js)
      Timeout.timeout(Capybara.default_max_wait_time) do
        loop do
          sleep 0.25
          break if page.evaluate_script("!!window.hyper_spec_promise_result")
        end
      end
      JSON.parse(page.evaluate_script("window.hyper_spec_promise_result.$to_json()"), opts).first
    end

    alias promise? evaluate_promise

    def expect_promise(str = '', opts = {}, &block)
      expect(evaluate_promise(add_opal_block(str, block), opts))
    end

    def ppr(str)
      js = opal_compile(str).delete("\n").gsub('(Opal);', '(Opal)')
      execute_script("console.log(#{js})")
    end

    def before_mount(&block) # was called on_client
      @_hyperspec_private_client_code =
        "#{@_hyperspec_private_client_code}#{Unparser.unparse Parser::CurrentRuby.parse(block.source).children.last}\n"
    end

    # to get legacy on_client behavior you can alias on_client before_mount

    alias on_client evaluate_ruby

    def debugger
      `debugger`
      nil
    end

    def insure_page_loaded(only_if_code_or_html_exists = nil)
      return if only_if_code_or_html_exists && !@_hyperspec_private_client_code && !@_hyperspec_private_html_block
      # if we are not resetting between examples, or think its mounted
      # then look for Opal, but if we can't find it, then ping to clear and try again
      if !HyperSpec.reset_between_examples? || page.instance_variable_get('@hyper_spec_mounted')
        r = evaluate_script('Opal && true') rescue nil
        return if r
        page.visit build_test_url_for(nil, true) rescue nil
      end
      load_page
    end

    def client_option(opts = {})
      @_hyperspec_private_client_options ||= {}
      @_hyperspec_private_client_options.merge! opts
    end

    alias client_options client_option

    def mount(component_name = nil, params = nil, opts = {}, &block)
      unless params
        params = opts
        opts = {}
      end

      opts = client_options opts
      test_url = build_test_url_for(opts.delete(:controller))
      if block || @_hyperspec_private_client_code || component_name.nil?
        block_with_helpers = <<-code
          module ComponentHelpers
            def self.js_eval(s)
              `eval(s)`
            end
            def self.dasherize(s)
              res = %x{
                s.replace(/[-_\\s]+/g, '-')
                .replace(/([A-Z\\d]+)([A-Z][a-z])/g, '$1-$2')
                .replace(/([a-z\\d])([A-Z])/g, '$1-$2')
                .toLowerCase()
              }
              res
            end
            def self.add_class(class_name, styles={})
              style = styles.collect { |attr, value| "\#{dasherize(attr)}:\#{value}" }.join("; ")
              cs = class_name.to_s
              %x{
                var style_el = document.createElement("style");
                var css = "." + cs + " { " + style + " }";
                style_el.type = "text/css";
                if (style_el.styleSheet){
                  style_el.styleSheet.cssText = css;
                } else {
                  style_el.appendChild(document.createTextNode(css));
                }
                document.head.appendChild(style_el);
              }
            end
          end
          # class React::Component::HyperTestDummy < React::Component::Base
          #       def render; end
          # end
          #{@_hyperspec_private_client_code}
          #{Unparser.unparse(Parser::CurrentRuby.parse(block.source).children.last) if block}
        code
        opts[:code] = opal_compile(block_with_helpers)
      end
      @_hyperspec_private_client_code = nil
      #component_name ||= 'React::Component::HyperTestDummy'
      value = [component_name, params, @_hyperspec_private_html_block, opts]
      ::Rails.cache.write(test_url, value)
      @_hyperspec_private_html_block = nil
      test_code_key = "hyper_spec_prerender_test_code.js"
      if defined? ::Hyperstack::Component # was ::React in old hyperloop version
        @@original_server_render_files ||= ::Rails.configuration.react.server_renderer_options[:files]
        if opts[:render_on] == :both || opts[:render_on] == :server_only
          unless opts[:code].blank?
            ::Rails.cache.write(test_code_key, opts[:code])
            ::Rails.configuration.react.server_renderer_options[:files] = @@original_server_render_files + [test_code_key]
            ::React::ServerRendering.reset_pool # make sure contexts are reloaded so they dont use code from cache, as the rails filewatcher doesnt look for cache changes
          else
            ::Rails.cache.delete(test_code_key)
            ::Rails.configuration.react.server_renderer_options[:files] = @@original_server_render_files
            ::React::ServerRendering.reset_pool # make sure contexts are reloaded so they dont use code from cache, as the rails filewatcher doesnt look for cache changes
          end
        end
      end
      page.instance_variable_set('@hyper_spec_mounted', false)
      visit test_url
      wait_for_ajax unless opts[:no_wait]
      page.instance_variable_set('@hyper_spec_mounted', true)
      Lolex.init(self, client_options[:time_zone], client_options[:clock_resolution])
    end

    def load_page
      mount
    end

    alias reload_page load_page

    [:callback_history_for, :last_callback_for, :clear_callback_history_for,
     :event_history_for, :last_event_for, :clear_event_history_for].each do |method|
      define_method(method) do |event_name|
        evaluate_ruby("Hyperstack::Internal::Component::TopLevelRailsComponent.#{method}('#{event_name}')")
      end
    end

    def run_on_client(&block)
      script = opal_compile(Unparser.unparse(Parser::CurrentRuby.parse(block.source).children.last))
      execute_script(script)
    end

    def add_class(class_name, style)
      @_hyperspec_private_client_code = "#{@_hyperspec_private_client_code}ComponentHelpers.add_class('#{class_name}', #{style})\n"
    end

    def open_in_chrome
      if false && ['linux', 'freebsd'].include?(`uname`.downcase)
        `google-chrome http://#{page.server.host}:#{page.server.port}#{page.current_path}`
      else
        `open http://#{page.server.host}:#{page.server.port}#{page.current_path}`
      end

      while true
        sleep 1.hour
      end
    end

    def pause(message = nil)
      if message
        puts message
        page.evaluate_ruby "puts #{message.inspect}.to_s + ' (type go() to continue)'"
      end

      page.evaluate_script('window.hyper_spec_waiting_for_go = true')

      loop do
        sleep 0.25
        break unless page.evaluate_script('window.hyper_spec_waiting_for_go')
      end
    end

    def wait_for_size(width, height)
      start_time = Capybara::Helpers.monotonic_time
      stable_count_w = 0
      stable_count_h = 0
      prev_size = [0, 0]
      begin
        sleep 0.05
        curr_size = Capybara.current_session.current_window.size
        return if [width, height] == curr_size
        # some maximum or minimum is reached and size doesnt change anymore
        stable_count_w += 1 if prev_size[0] == curr_size[0]
        stable_count_h += 1 if prev_size[1] == curr_size[1]
        return if stable_count_w > 2 || stable_count_h > 2
        prev_size = curr_size
      end while (Capybara::Helpers.monotonic_time - start_time) < Capybara.current_session.config.default_max_wait_time
      raise Capybara::WindowError, "Window size not stable within #{Capybara.current_session.config.default_max_wait_time} seconds."
    end

    def size_window(width = nil, height = nil)
      # return if @window_cannot_be_resized
      # original_width = evaluate_script('window.innerWidth')
      # original_height = evaluate_script('window.innerHeight')
      width, height = [height, width] if width == :portrait
      width, height = width if width.is_a? Array
      portrait = true if height == :portrait

      case width
      when :small
        width, height = [480, 320]
      when :mobile
        width, height = [640, 480]
      when :tablet
        width, height = [960, 640]
      when :large
        width, height = [1920, 6000]
      when :default, nil
        width, height = [1024, 768]
      end

      width, height = [height, width] if portrait

      unless RSpec.configuration.debugger_width
        Capybara.current_session.current_window.resize_to(1000, 500)
        wait_for_size(1000, 500)
        inner_width = evaluate_script('window.innerWidth')
        RSpec.configuration.debugger_width = 1000 - inner_width
      end
      Capybara.current_session.current_window
              .resize_to(width + RSpec.configuration.debugger_width, height)
      wait_for_size(width + RSpec.configuration.debugger_width, height)
    end
  end

  RSpec.configure do |config|
    config.before(:each) do |example|
      ComponentTestHelpers.current_example = example
      ComponentTestHelpers.description_displayed = false
    end

    if defined?(ActiveRecord)
      config.before(:all) do
        ActiveRecord::Base.class_eval do
          def attributes_on_client(page)
            page.evaluate_ruby("#{self.class.name}.find(#{id}).attributes", symbolize_names: true)
          end
        end
      end
    end
  end
end



module RSpec
  module Expectations
    class ExpectationTarget
    end

    module HyperSpecInstanceMethods

      def self.included(base)
        base.include HyperSpec::ComponentTestHelpers
      end

      def to_on_client(matcher, message = nil, &block)
        evaluate_client('ruby').to(matcher, message, &block)
      end

      alias on_client_to to_on_client

      def to_on_client_not(matcher, message = nil, &block)
        evaluate_client('ruby').not_to(matcher, message, &block)
      end

      alias on_client_to_not to_on_client_not
      alias on_client_not_to to_on_client_not
      alias to_not_on_client to_on_client_not
      alias not_to_on_client to_on_client_not

      def to_then(matcher, message = nil, &block)
        evaluate_client('promise').to(matcher, message, &block)
      end

      alias then_to to_then

      def to_then_not(matcher, message = nil, &block)
        evaluate_client('promise').not_to(matcher, message, &block)
      end

      alias then_to_not to_then_not
      alias then_not_to to_then_not
      alias to_not_then to_then_not
      alias not_to_then to_then_not

      private

      def evaluate_client(method)
        source = add_opal_block(@args_str, @target)
        value = @target.binding.eval("evaluate_#{method}(#{source.inspect}, {}, {})")
        ExpectationTarget.for(value, nil)
      end
    end

    class OnClientWithArgsTarget
      include HyperSpecInstanceMethods

      def initialize(target, args)
        unless args.is_a? Hash
          raise ExpectationNotMetError,
                "You must pass a hash of local var, value pairs to the 'with' modifier"
        end

        @target = target
        @args_str = args.collect do |name, value|
          "#{name} = #{value.to_opal_expression}"
        end.join("\n")
      end
    end

    class BlockExpectationTarget < ExpectationTarget
      include HyperSpecInstanceMethods

      def with(args)
        OnClientWithArgsTarget.new(@target, args)
      end
    end
  end
end
