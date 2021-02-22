module HyperSpec
  module Helpers
    include Internal::ClientExecution
    include Internal::Controller
    include Internal::ComponentMount
    include Internal::CopyLocals
    include Internal::WindowSizing

    ##
    # Mount a component on a page, with a full execution environment
    # i.e. `mount('MyComponent')` will mount MyComponent on the page.

    # The params argument is a hash of parameters to be passed to the
    # component.
    # i.e. `mount('MyComponent', title: 'hello')`

    # The options parameters can set things like:
    # + controller: the controller class, defaults to HyperSpecTestController
    # + no_wait: do not wait for any JS to finish executing before proceeding with the spec
    # + render_on: :client_only (default), :client_and_server, or :server_only
    # + style_sheet: style sheet file defaults to 'application'
    # + javascript:  javascript file defaults to 'application'
    # + layout: if provided will use the specified layout otherwise no layout is used
    # Note that if specifying options the params will have to inclosed in their
    # own hash.
    # i.e. `mount('MyComponent', { title: 'hello' }, render_on: :server_only)`
    # The options can be specified globally using the client_options method (see below.)

    # You may provide a block to mount.  This block will be executed on the client
    # before mounting the component.  This is useful for setting up test
    # components or modifying a components behavior.
    # i.e.
    # ```ruby
    # mount('MyComponent', title: 'hello') do
    #   # this line will be printed on the client console
    #   puts "I'm about to mount my component!"
    # end
    # ```
    def mount(component_name = nil, params = nil, opts = {}, &block)
      unless params
        params = opts
        opts = {}
      end
      internal_mount(component_name, params, client_options(opts), &block)
    end

    ##
    # The following methods retrieve callback and event responses from
    # the mounted components.  The history methods contain the array of all
    # responses, while last_... returns the last response.
    # i.e. event_history_for(:save) would return any save events
    # that the component has raised.

    %i[
      callback_history_for last_callback_for clear_callback_history_for
      event_history_for last_event_for clear_event_history_for
    ].each do |method|
      define_method(method) do |event_name|
        evaluate_ruby(
          "Hyperstack::Internal::Component::TopLevelRailsComponent.#{method}('#{event_name}')"
        )
      end
    end

    ##
    # Define a code block to be prefixed to the mount code.
    # Useful in before(:each) blocks.

    # In legacy code this was called `on_client`. To get the legacy
    # behavior alias on_client before_mount
    # but be aware that on_client is now by default the method
    # for executing a block of code on the client which was called
    # evaluate_ruby

    def before_mount(&block)
      @_hyperspec_private_client_code =
        "#{@_hyperspec_private_client_code}"\
        "#{Unparser.unparse Parser::CurrentRuby.parse(block.source).children.last}\n"
    end

    # Execute the block both on the client and on the server.  Useful
    # for mocking isomorphic classes such as ActiveRecord models.

    def isomorphic(&block)
      yield
      before_mount(&block)
    end

    # Allows options to the mount method to be specified globally

    def client_option(opts = {})
      @_hyperspec_private_client_options ||= {}
      @_hyperspec_private_client_options.merge! opts
      build_var_inclusion_lists
      @_hyperspec_private_client_options
    end

    alias client_options client_option

    ##
    # shorthand for mount with no params (which will effectively reload the page.)
    # also aliased as reload_page
    def load_page
      mount
    end

    alias reload_page load_page

    ##
    # evaluate a block (or string) on the client
    #   on_client(<optional str>, <opts and/or vars>, &block)
    #
    # normal use is to pass a block that will be compiled to the client
    # but if the ruby code can be supplied as a string in the first arg.

    # opts are passed on to JSON.parse when retrieving the result
    # from the client.

    # vars is a hash of name: value pairs.  Each name will be initialized
    # as a local variable on the client.

    # example: on_client(x: 12) { x * x } => 144

    # in legacy code on_client was called before_mount
    # to get legacy on_client behavior you can alias
    # on_client before_mount

    alias on_client internal_evaluate_ruby

    # attempt to set the window to a particular size

    def size_window(width = nil, height = nil)
      hs_internal_resize_to(*determine_size(width, height))
    rescue StandardError
      true
    end

    # same signature as on_client, but just returns the compiled
    # js code.  Useful for debugging suspected issues with the
    # Opal compiler, etc.

    def to_js(*args, &block)
      opal_compile(*process_params(*args, &block))
    end

    # legacy methods for backwards compatibility
    # these may be removed in a future version

    def expect_evaluate_ruby(*args, &block)
      expect(evaluate_ruby(*args, &block))
    end

    alias evaluate_ruby internal_evaluate_ruby
    alias evaluate_promise evaluate_ruby
    alias expect_promise expect_evaluate_ruby

    def run_on_client(&block)
      script = opal_compile(Unparser.unparse(Parser::CurrentRuby.parse(block.source).children.last))
      page.execute_script(script)
    end

    def insert_html(str)
      @_hyperspec_private_html_block = "#{@_hyperspec_private_html_block}\n#{str}"
    end

    def ppr(str)
      js = Opal.hyperspec_compile(str)
      execute_script("console.log(#{js})")
    end

    def debugger
      `debugger`
      nil
    end

    def add_class(class_name, style)
      @_hyperspec_private_client_code =
        "#{@_hyperspec_private_client_code}ComponentHelpers.add_class('#{class_name}', #{style})\n"
    end

    def attributes_on_client(model)
      evaluate_ruby("#{model.class.name}.find(#{model.id}).attributes").symbolize_keys
    end

    ### --- Debugging Helpers ----

    def pause(message = nil)
      if message
        puts message
        internal_evaluate_ruby "puts #{message.inspect}.to_s + ' (type go() to continue)'"
      end

      page.evaluate_script('window.hyper_spec_waiting_for_go = true')

      loop do
        sleep 0.25
        break unless page.evaluate_script('window.hyper_spec_waiting_for_go')
      end
    end

    def open_in_chrome
      # if ['linux', 'freebsd'].include?(`uname`.downcase)
      #   `google-chrome http://#{page.server.host}:#{page.server.port}#{page.current_path}`
      # else
      `open http://#{page.server.host}:#{page.server.port}#{page.current_path}`
      # end

      loop do
        sleep 1.hour
      end
    end

    # short hand for use in pry sessions
    alias c? internal_evaluate_ruby
  end
end
