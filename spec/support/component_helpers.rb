# see component_test_helpers_spec.rb for examples

require 'parser/current'
require 'unparser'
require 'pry'

module ComponentTestHelpers

  def self.compile_to_opal(&block)
    Opal.compile(block.source.split("\n")[1..-2].join("\n"))
  end


  TOP_LEVEL_COMPONENT_PATCH = lambda { |&block| Opal.compile(block.source.split("\n")[1..-2].join("\n"))}.call do #ComponentTestHelpers.compile_to_opal do
    module React
      class TopLevelRailsComponent

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
          if params.component_name.start_with? "::"
            paths_searched << params.component_name.gsub(/^\:\:/,"")
            @component = params.component_name.gsub(/^\:\:/,"").split("::").inject(Module) { |scope, next_const| scope.const_get(next_const, false) } rescue nil
            return @component if @component && @component.method_defined?(:render)
          else
            self.class.search_path.each do |path|
              # try each path + params.controller + params.component_name
              paths_searched << "#{path.name + '::' unless path == Module}#{params.controller}::#{params.component_name}"
              @component = "#{params.controller}::#{params.component_name}".split("::").inject(path) { |scope, next_const| scope.const_get(next_const, false) } rescue nil
              return @component if @component && @component.method_defined?(:render)
            end
            self.class.search_path.each do |path|
              # then try each path + params.component_name
              paths_searched << "#{path.name + '::' unless path == Module}#{params.component_name}"
              @component = "#{params.component_name}".split("::").inject(path) { |scope, next_const| scope.const_get(next_const, false) } rescue nil
              return @component if @component && @component.method_defined?(:render)
            end
          end
          @component = nil
          raise "Could not find component class '#{params.component_name}' for params.controller '#{params.controller}' in any component directory. Tried [#{paths_searched.join(", ")}]"
        end

        before_mount do
          TopLevelRailsComponent.event_history = Hash.new {|h,k| h[k] = [] }
          @render_params = params.render_params.dup
          component.validator.rules.each do |name, rules|
            if rules[:type] == Proc
              TopLevelRailsComponent.event_history[name] = []
              @render_params[name] = lambda { |*args| TopLevelRailsComponent.event_history[name] << args.collect { |arg| Native(arg).to_n } }
            end
          end
        end

        def render
          present component, @render_params
        end
      end
    end
  end

  def build_test_url_for(controller)

    unless controller
      Object.const_set("ReactTestController", Class.new(ActionController::Base)) unless defined?(::ReactTestController)
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
          render_on = render_params.delete(:render_on) || :both
          mock_time = render_params.delete(:mock_time)
          style_sheet = render_params.delete(:style_sheet)
          javascript = render_params.delete(:javascript)
          code = render_params.delete(:code)
          page = "<%= react_component @component_name, @component_params, { prerender: false } %>" # false should be:  "#{render_on != :client_only} } %>" but its not working in the gem testing harness
          page = "<script type='text/javascript'>\n//HELLO HELLO HELLO\n#{TOP_LEVEL_COMPONENT_PATCH}\n</script>\n"+page

          if code
            page = "<script type='text/javascript'>\n#{code}\n</script>\n"+page
          end

          #TODO figure out how to auto insert this line????  something like:
          page = "<%= javascript_include_tag 'hyper-router' %>\n#{page}"

          if (render_on != :server_only && !render_params[:layout]) || javascript
            page = "<%= javascript_include_tag '#{javascript || 'application'}' %>\n"+page
          end
          if mock_time || (defined?(Timecop) && Timecop.top_stack_item)
            unix_millis = ((mock_time || Time.now).to_f * 1000.0).to_i
            page = "<%= javascript_include_tag 'spec/libs/lolex' %>\n"+
            "<script type='text/javascript'>\n"+
            "  window.original_setInterval = setInterval;\n"+
            "  window.lolex_clock = lolex.install(#{unix_millis});\n"+
            "  window.original_setInterval(function() {window.lolex_clock.tick(10)}, 10);\n"+
            "</script>\n"+page
          end
          if !render_params[:layout] || style_sheet
            page = "<%= stylesheet_link_tag '#{style_sheet || 'application'}' %>\n"+page
          end
          if render_on == :server_only # so that test helper wait_for_ajax works
            page = "<script type='text/javascript'>window.jQuery = {'active': 0}</script>\n#{page}"
          else
            page = "<%= javascript_include_tag 'jquery' %>\n<%= javascript_include_tag 'jquery_ujs' %>\n#{page}"
          end

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

  def on_client(&block)
    @client_code = "#{@client_code}#{Unparser.unparse Parser::CurrentRuby.parse(block.source).children.last}\n"
  end

  def debugger
    `debugger`
    nil
  end

  def mount(component_name, params=nil, opts = {}, &block)
    unless params
      params = opts
      opts = {}
    end
    test_url = build_test_url_for(opts.delete(:controller))
    if block
      block_with_helpers = <<-code
        module ComponentHelpers
          def self.js_eval(s)
            `eval(s)`
          end
          def self.add_class(class_name, styles={})
            style = styles.collect { |attr, value| "\#{attr.dasherize}:\#{value}"}.join("; ")
            s = "<style type='text/css'> .\#{class_name}{ \#{style} } </style>"
            `$(\#{s}).appendTo("head");`
          end
        end
        #{@client_code}
        #{Unparser.unparse Parser::CurrentRuby.parse(block.source).children.last}
      code
      opts[:code] = Opal.compile(block_with_helpers)
    end
    Rails.cache.write(test_url, [component_name, params, opts])
    visit test_url
    wait_for_ajax
  end

  [:callback_history_for, :last_callback_for, :clear_callback_history_for, :event_history_for, :last_event_for, :clear_event_history_for].each do |method|
    define_method(method) { |event_name| evaluate_script("Opal.React.TopLevelRailsComponent.$#{method}('#{event_name}')") }
  end

  def run_on_client(&block)
    script = Opal.compile(Unparser.unparse Parser::CurrentRuby.parse(block.source).children.last)
    execute_script(script)
  end

  def open_in_chrome
    on_linux = `which google-chrome`
    if on_linux
      `google-chrome http://#{page.server.host}:#{page.server.port}#{page.current_path}`
    else
      `open http://#{page.server.host}:#{page.server.port}#{page.current_path}`
    end
    while true
      sleep 1.hour
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

end
