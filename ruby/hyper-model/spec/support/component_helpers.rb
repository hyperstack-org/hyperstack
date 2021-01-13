# see component_test_helpers_spec.rb for examples

require 'parser/current'
require 'unparser'

Parser::Builders::Default.emit_procarg0 = true

#require 'pry'

module ComponentTestHelpers

  def self.compile_to_opal(&block)
    Opal.compile(block.source.split("\n")[1..-2].join("\n"))
  end


  TOP_LEVEL_COMPONENT_PATCH = lambda { |&block| Opal.compile(block.source.split("\n")[1..-2].join("\n"))}.call do #ComponentTestHelpers.compile_to_opal do
    module Hyperstack
      module Internal
        module Component
          class TopLevelRailsComponent

            # original class declares these params:
            # param :component_name
            # param :controller
            # param :render_params

            class << self
              attr_accessor :event_history

              def callback_history_for(proc_name)
                event_history[proc_name]
              end

              def last_callback_for(proc_name)
                event_history[proc_name].last
              end

              def clear_callback_history_for(proc_name)
                event_history[proc_name] = []
              end

              def event_history_for(event_name)
                event_history["on_#{event_name}"]
              end

              def last_event_for(event_name)
                event_history["on_#{event_name}"].last
              end

              def clear_event_history_for(event_name)
                event_history["on_#{event_name}"] = []
              end
            end

            def component
              return @component if @component
              paths_searched = []
              component = nil
              if @ComponentName.start_with?('::')
                # if absolute path of component is given, look it up and fail if not found
                paths_searched << @ComponentName
                component = begin
                              Object.const_get(@ComponentName)
                            rescue NameError
                              nil
                            end
              else
                # if relative path is given, look it up like this
                # 1) we check each path + controller-name + component-name
                # 2) if we can't find it there we check each path + component-name
                # if we can't find it we just try const_get
                # so (assuming controller name is Home)
                # ::Foo::Bar will only resolve to some component named ::Foo::Bar
                # but Foo::Bar will check (in this order) ::Home::Foo::Bar, ::Components::Home::Foo::Bar, ::Foo::Bar, ::Components::Foo::Bar
                self.class.search_path.each do |scope|
                  paths_searched << "#{scope.name}::#{@Controller}::#{@ComponentName}"
                  component = begin
                                scope.const_get(@Controller, false).const_get(@ComponentName, false)
                              rescue NameError
                                nil
                              end
                  break if component != nil
                end
                unless component
                  self.class.search_path.each do |scope|
                    paths_searched << "#{scope.name}::#{@ComponentName}"
                    component = begin
                                  scope.const_get(@ComponentName, false)
                                rescue NameError
                                  nil
                                end
                    break if component != nil
                  end
                end
              end
              @component = component
              return @component if @component && @component.method_defined?(:render)
              raise "Could not find component class '#{@ComponentName}' for @Controller '#{@Controller}' in any component directory. Tried [#{paths_searched.join(", ")}]"
            end

            before_mount do
              TopLevelRailsComponent.event_history = Hash.new { |h, k| h[k] = [] }
              component.validator.rules.each do |name, rules|
                next unless rules[:type] == Proc

                TopLevelRailsComponent.event_history[name] = []
                @RenderParams[name] = lambda do |*args|
                  TopLevelRailsComponent.event_history[name] << args
                end
              end
            end

            def render
              Hyperstack::Internal::Component::RenderingContext.render(component, @RenderParams)
            end
          end
        end
      end
    end

    # module React
    #   class TopLevelRailsComponent # NEEDS TO BE Hyperstack::Internal::Component::TopLevelRailsComponent
    #
    #     class << self
    #       attr_accessor :event_history
    #
    #       def callback_history_for(proc_name)
    #         event_history[proc_name]
    #       end
    #
    #       def last_callback_for(proc_name)
    #         event_history[proc_name].last
    #       end
    #
    #       def clear_callback_history_for(proc_name)
    #         event_history[proc_name] = []
    #       end
    #
    #       def event_history_for(event_name)
    #         event_history["_on#{event_name.event_camelize}"]
    #       end
    #
    #       def last_event_for(event_name)
    #         event_history["_on#{event_name.event_camelize}"].last
    #       end
    #
    #       def clear_event_history_for(event_name)
    #         event_history["_on#{event_name.event_camelize}"] = []
    #       end
    #
    #     end
    #
    #     def component
    #       return @component if @component
    #       paths_searched = []
    #       component = nil
    #       if params.component_name.start_with?('::')
    #         # if absolute path of component is given, look it up and fail if not found
    #         paths_searched << params.component_name
    #         component = begin
    #                       Object.const_get(params.component_name)
    #                     rescue NameError
    #                       nil
    #                     end
    #       else
    #         # if relative path is given, look it up like this
    #         # 1) we check each path + controller-name + component-name
    #         # 2) if we can't find it there we check each path + component-name
    #         # if we can't find it we just try const_get
    #         # so (assuming controller name is Home)
    #         # ::Foo::Bar will only resolve to some component named ::Foo::Bar
    #         # but Foo::Bar will check (in this order) ::Home::Foo::Bar, ::Components::Home::Foo::Bar, ::Foo::Bar, ::Components::Foo::Bar
    #         self.class.search_path.each do |scope|
    #           paths_searched << "#{scope.name}::#{params.controller}::#{params.component_name}"
    #           component = begin
    #                         scope.const_get(params.controller, false).const_get(params.component_name, false)
    #                       rescue NameError
    #                         nil
    #                       end
    #           break if component != nil
    #         end
    #         unless component
    #           self.class.search_path.each do |scope|
    #             paths_searched << "#{scope.name}::#{params.component_name}"
    #             component = begin
    #                           scope.const_get(params.component_name, false)
    #                         rescue NameError
    #                           nil
    #                         end
    #             break if component != nil
    #           end
    #         end
    #       end
    #       @component = component
    #       return @component if @component && @component.method_defined?(:render)
    #       raise "Could not find component class '#{params.component_name}' for params.controller '#{params.controller}' in any component directory. Tried [#{paths_searched.join(", ")}]"
    #     end
    #
    #     before_mount do
    #       # NEEDS TO BE Hyperstack::Internal::Component::TopLevelRailsComponent
    #       TopLevelRailsComponent.event_history = Hash.new {|h,k| h[k] = [] }
    #       component.validator.rules.each do |name, rules|
    #         if rules[:type] == Proc
    #           # NEEDS TO BE Hyperstack::Internal::Component::TopLevelRailsComponent
    #           TopLevelRailsComponent.event_history[name] = []
    #           params.render_params[name] = lambda { |*args|  TopLevelRailsComponent.event_history[name] << args.collect { |arg| Native(arg).to_n } }
    #         end
    #       end
    #     end
    #
    #     def render
    #       Hyperstack::Internal::Component::RenderingContext.render(component, params.render_params)
    #     end
    #   end
    # end
  end

  def build_test_url_for(controller)

    unless controller
      Object.const_set("ReactTestController", Class.new(ApplicationController)) unless defined?(::ReactTestController)
      controller = ::ReactTestController
    end

    route_root = controller.name.gsub(/Controller$/,"").underscore

    unless controller.method_defined? :test
      controller.class_eval do
        define_method(:test) do
          route_root = self.class.name.gsub(/Controller$/,"").underscore
          test_params = Rails.cache.read("/#{route_root}/#{params[:id]}")
          @component_name = test_params[0]
          @component_params = test_params[1]
          render_params = test_params[2]
          render_on = render_params.delete(:render_on) || :client_only
          mock_time = render_params.delete(:mock_time)
          style_sheet = render_params.delete(:style_sheet)
          javascript = render_params.delete(:javascript)
          code = render_params.delete(:code)
          page = "<%= react_component @component_name, @component_params, { prerender: #{render_on != :client_only} } %>"  # false should be:  "#{render_on != :client_only} } %>" but its not working in the gem testing harness
          unless render_on == :server_only
            page = "<script type='text/javascript'>\n#{TOP_LEVEL_COMPONENT_PATCH}\n</script>\n#{page}"
            page = "<script type='text/javascript'>\n#{code}\n</script>\n"+page if code
          end

          #TODO figure out how to auto insert this line????  something like:
          #page = "<%= javascript_include_tag 'reactrb-router' %>\n#{page}"

          if (render_on != :server_only && !render_params[:layout]) || javascript
            #page = "<script src='/assets/application.js?ts=#{Time.now.to_f}'></script>\n"+page
            page = "<%= javascript_include_tag '#{javascript || 'application'}' %>\n"+page
          end
          if mock_time || (defined?(Timecop) && Timecop.top_stack_item)
            puts "********** WARNING LOLEX NOT AVAILABLE TIME ON CLIENT WILL NOT MATCH SERVER **********"
            # unix_millis = ((mock_time || Time.now).to_f * 1000.0).to_i
            # page = "<%= javascript_include_tag 'spec/libs/lolex' %>\n"+
            # "<script type='text/javascript'>\n"+
            # "  window.original_setInterval = setInterval;\n"+
            # "  window.lolex_clock = lolex.install(#{unix_millis});\n"+
            # "  window.original_setInterval(function() {window.lolex_clock.tick(10)}, 10);\n"+
            # "</script>\n"+page
          end
          if !render_params[:layout] || style_sheet
            page = "<%= stylesheet_link_tag '#{style_sheet || 'application'}' rescue nil %>\n"+page
          end
          page = "<script type='text/javascript'>go = function() {window.hyper_spec_waiting_for_go = false}</script>\n#{page}"
          title = view_context.escape_javascript(ComponentTestHelpers.current_example.description)
          title = "#{title}...continued." if ComponentTestHelpers.description_displayed
          page = "<script type='text/javascript'>console.log('%c#{title}','color:green; font-weight:bold; font-size: 200%')</script>\n#{page}"
          ComponentTestHelpers.description_displayed = true
          render_params[:inline] = page
          render render_params
        end
      end

      # test_routes = Proc.new do
      #   get "/#{route_root}/:id", to: "#{route_root}#test"
      # end
      # Rails.application.routes.eval_block(test_routes)

      begin
        routes = Rails.application.routes
        routes.disable_clear_and_finalize = true
        routes.clear!
        routes.draw do
          get "/#{route_root}/:id", to: "#{route_root}#test"
        end
        Rails.application.routes_reloader.paths.each{ |path| load(path) }
        routes.finalize!
        ActiveSupport.on_load(:action_controller) { routes.finalize! }
      ensure
        routes.disable_clear_and_finalize = false
      end
    end

    "/#{route_root}/#{@test_id = (@test_id || 0) + 1}"

  end

  def isomorphic(&block)
    yield
    on_client(&block)
  end

  def evaluate_ruby(str="", opts={}, &block)
    insure_mount
    str = "#{str}\n#{Unparser.unparse Parser::CurrentRuby.parse(block.source).children.last}" if block
    js = Opal.compile(str).gsub("// Prepare super implicit arguments\n", "").gsub("\n","").gsub("(Opal);","(Opal)")
    JSON.parse(evaluate_script("[#{js}].$to_json()"), opts).first
  end

  def expect_evaluate_ruby(str = '', opts = {}, &block)
    expect(evaluate_ruby(add_opal_block(str, block), opts))
  end

  def add_opal_block(str, block)
    # big assumption here is that we are going to follow this with a .to
    # hence .children.first followed by .children.last
    # probably should do some kind of "search" to make this work nicely
    return str unless block
    "#{str}\n"\
    "#{Unparser.unparse Parser::CurrentRuby.parse(block.source).children.first.children.last}"
  end

  def evaluate_promise(str = '', opts = {}, &block)
    insure_mount
    str = "#{str}\n#{Unparser.unparse Parser::CurrentRuby.parse(block.source).children.last}" if block
    str = "#{str}.then { |args| args = [args]; `window.hyper_spec_promise_result = args` }"
    js = Opal.compile(str).gsub("\n","").gsub("(Opal);","(Opal)")
    page.evaluate_script("window.hyper_spec_promise_result = false")
    page.execute_script(js)
    Timeout.timeout(100) do #Capybara.default_max_wait_time) do
      loop do
        sleep 0.25
        break if page.evaluate_script("!!window.hyper_spec_promise_result")
      end
    end
    JSON.parse(page.evaluate_script("window.hyper_spec_promise_result.$to_json()"), opts).first
  end

  def expect_promise(str = '', opts = {}, &block)
    insure_mount
    expect(evaluate_promise(add_opal_block(str, block), opts))
  end

  def ppr(str)
    js = Opal.compile(str).gsub("\n","").gsub("(Opal);","(Opal)")
    execute_script("console.log(#{js})")
  end


  def on_client(&block)
    @client_code = "#{@client_code}#{Unparser.unparse Parser::CurrentRuby.parse(block.source).children.last}\n"
  end

  def debugger
    `debugger`
    nil
  end

  class << self
    attr_accessor :current_example
    attr_accessor :description_displayed
    def display_example_description
      "<script type='text/javascript'>console.log(console.log('%c#{current_example.description}','color:green; font-weight:bold; font-size: 200%'))</script>"
    end
  end

  def insure_mount
    # rescue in case page is not defined...
    mount unless page.instance_variable_get("@hyper_spec_mounted") rescue nil
  end

  def client_option(opts = {})
    @client_options ||= {}
    @client_options.merge! opts
  end

  alias client_options client_option

  def mount(component_name = nil, params = nil, opts = {}, &block)
    unless params
      params = opts
      opts = {}
    end
    test_url = build_test_url_for(opts.delete(:controller))
    if block || @client_code || component_name.nil?
      block_with_helpers = <<-code
        module ComponentHelpers
          def self.js_eval(s)
            `eval(s)`
          end
          def self.dasherize(s)
            %x{
              return s.replace(/[-_\\s]+/g, '-')
              .replace(/([A-Z\\d]+)([A-Z][a-z])/g, '$1-$2')
              .replace(/([a-z\\d])([A-Z])/g, '$1-$2')
              .toLowerCase()
            }
          end
          def self.add_class(class_name, styles={})
            style = styles.collect { |attr, value| "\#{dasherize(attr)}:\#{value}"}.join("; ")
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
        class HyperComponent::HyperTestDummy < HyperComponent
          render {}
        end
        #{@client_code}
        #{Unparser.unparse(Parser::CurrentRuby.parse(block.source).children.last) if block}
      code
      opts[:code] = Opal.compile(block_with_helpers)
    end
    component_name ||= 'HyperComponent::HyperTestDummy'
    ::Rails.cache.write(test_url, [component_name, params, opts])

    # this code copied from latest hyper-spec
    test_code_key = "hyper_spec_prerender_test_code.js"
    #::Rails.configuration.react.server_renderer_options[:files] ||= ['hyperstack-prerender-loader.js']
    @@original_server_render_files ||= ::Rails.configuration.react.server_renderer_options[:files] || [] #'hyperstack-prerender-loader.js']
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
    # end of copied code

    visit test_url
    wait_for_ajax unless opts[:no_wait]
    page.instance_variable_set("@hyper_spec_mounted", true)
  end

  [:callback_history_for, :last_callback_for, :clear_callback_history_for, :event_history_for, :last_event_for, :clear_event_history_for].each do |method|
    define_method(method) { |event_name| evaluate_script("Opal.React.TopLevelRailsComponent.$#{method}('#{event_name}')") }
  end

  def run_on_client(&block)
    script = Opal.compile(Unparser.unparse Parser::CurrentRuby.parse(block.source).children.last)
    execute_script(script)
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
      evaluate_ruby "puts #{message.inspect}.to_s + ' (type go() to continue)'"
    end
    page.evaluate_script("window.hyper_spec_waiting_for_go = true")
    loop do
      sleep 0.25
      break unless page.evaluate_script("window.hyper_spec_waiting_for_go")
    end
  end

  def size_window(width=nil, height=nil)
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
    if portrait
      width, height = [height, width]
    end
    if page.driver.browser.respond_to?(:manage)
      page.driver.browser.manage.window.resize_to(width, height)
    elsif page.driver.respond_to?(:resize)
      page.driver.resize(width, height)
    end
  end

  def check_errors
    logs = page.driver.browser.manage.logs.get(:browser)
    errors = logs.select { |e| e.level == "SEVERE" && e.message.present? }
                .map { |m| m.message.gsub(/\\n/, "\n") }.to_a
    puts "WARNING - FOUND UNEXPECTED ERRORS #{errors}" if errors.present?
  end

end

RSpec.configure do |config|
  config.before(:each) do |example|
    ComponentTestHelpers.current_example = example
    ComponentTestHelpers.description_displayed = false
  end
  config.before(:all) do
    ActiveRecord::Base.class_eval do
      def attributes_on_client(page)
        evaluate_ruby("#{self.class.name}.find(#{id}).attributes", symbolize_names: true)
      end
    end
  end
end
