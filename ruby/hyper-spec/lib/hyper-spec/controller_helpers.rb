module HyperSpec
  module ControllerHelpers
    TOP_LEVEL_COMPONENT_PATCH =
      Opal.compile(File.read(File.expand_path('../../sources/top_level_rails_component.rb', __FILE__)))
    TIME_COP_CLIENT_PATCH =
      Opal.compile(File.read(File.expand_path('../../hyper-spec/time_cop.rb', __FILE__))) +
      "\n#{File.read(File.expand_path('../../sources/lolex.js', __FILE__))}"

    def self.included(base)
      def base.route_root
        # Implement underscore without using rails underscore, so we don't have a
        # dependency on ActiveSupport
        name.gsub(/Controller$/, '')
            .gsub(/::/, '/')
            .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
            .gsub(/([a-z\d])([A-Z])/, '\1_\2')
            .tr('-', '_')
            .downcase
      end
    end

    def initialize!
      return ping! if params[:id] == 'ping'

      key =               "/#{self.class.route_root}/#{params[:id]}"
      test_params =       ComponentTestHelpers.cache_read(key)

      @component_name =   test_params[0]
      @component_params = test_params[1]
      @html_block =       test_params[2]
      @render_params =    test_params[3]
      @render_on =        @render_params.delete(:render_on) || :client_only
      @_mock_time =       @render_params.delete(:mock_time)
      @style_sheet =      @render_params.delete(:style_sheet)
      @javascript =       @render_params.delete(:javascript)
      @code =             @render_params.delete(:code)

      @page = "</body>\n"
    end

    def ping!
      head(:no_content)
      nil
    end

    def mount_component!
      @page = '<%= react_component @component_name, @component_params, '\
              "{ prerender: #{@render_on != :client_only} } %>\n#{@page}"
    end

    def client_code!
      if @component_name
        @page = "<script type='text/javascript'>\n#{TOP_LEVEL_COMPONENT_PATCH}\n</script>\n#{@page}"
      end
      @page = "<script type='text/javascript'>\n#{@code}\n</script>\n#{@page}" if @code
    end

    def time_cop_patch!
      @page = "<script type='text/javascript'>\n#{TIME_COP_CLIENT_PATCH}\n</script>\n#{@page}"
    end

    def application!
      @page = "<%= javascript_include_tag '#{@javascript || 'application'}' %>\n#{@page}"
    end

    def style_sheet!
      @page = "<%= stylesheet_link_tag '#{@style_sheet || 'application'}' %>\n#{@page}"
    end

    def go_function!
      @page = "<script type='text/javascript'>go = function() "\
              "{window.hyper_spec_waiting_for_go = false}</script>\n#{@page}"
    end

    def escape_javascript(str)
      ComponentTestHelpers.escape_javascript(str)
    end

    def client_title!
      title =
        ComponentTestHelpers.escape_javascript(ComponentTestHelpers.current_example.description)
      title = "#{title}...continued." if ComponentTestHelpers.description_displayed

      @page = "<script type='text/javascript'>console.log('%c#{title}',"\
              "'color:green; font-weight:bold; font-size: 200%')</script>\n#{@page}"

      ComponentTestHelpers.description_displayed = true
    end

    def html_block!
      @page = "<body>\n#{@html_block}\n#{@page}"
    end

    def deliver!
      @render_params[:inline] = @page
      response.headers['Cache-Control'] = 'max-age=120'
      response.headers['X-Tracking-ID'] = '123456'
      render @render_params
    end

    def server_only?
      @render_on == :server_only
    end

    def test
      return unless initialize!

      # TODO: reverse the the layout in the above methods so they can run in
      # the right order
      mount_component! if @component_name
      client_code!     unless server_only?
      time_cop_patch!  if !server_only? || Lolex.initialized?
      application!     if (!server_only? && !@render_params[:layout]) || @javascript
      style_sheet!     if !@render_params[:layout] || @style_sheet
      go_function!
      client_title!    if ComponentTestHelpers.current_example
      html_block!
      deliver!
    end
  end
end
