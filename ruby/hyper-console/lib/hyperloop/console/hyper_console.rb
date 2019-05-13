if RUBY_ENGINE=='opal'
  module Kernel
    def console(title: nil, context: nil)
      Hyperloop::Console.console(title: title, context: context)
    end
  end

  module Hyperloop
    module Console
      def self.console_id
        @console_id ||= (
          `sessionStorage.getItem('Hyperloop::Console::MainWindowId')` ||
          SecureRandom.uuid.tap { |id| `sessionStorage.setItem('Hyperloop::Console::MainWindowId', #{id})` }
          )
      end

      def self.messenger(target_id, kind, m)
        Response.run(target_id: target_id, kind: kind, message: m.gsub(/\n$/, ''))
      end

      def self.console(title: nil, context: nil)
        title ||= context || 'Hyperloop Application Console'
        title = `encodeURIComponent(#{title})`
        context = `encodeURIComponent(#{context})`
        location = "/hyperloop/hyperloop-debug-console/#{console_id}?context=#{context}&title=#{title}"
        window_params = 'width=640,height=460,scrollbars=no,location=0'
        `window.open(#{location}, #{"window#{title}"}, #{window_params}).focus()`
        @__console_dispatcher__ ||= Evaluate.on_dispatch do |params|
          if params.target_id == console_id
            cwarn =  `console.warn`
            clog =   `console.log`
            cerror = `console.error`
            cinfo =  `console.info`
            `console.warn =  function(m) { #{messenger(params.sender_id, :warn,  `m`)} }`
            `console.log =   function(m) { #{messenger(params.sender_id, :log,   `m`)} }`
            `console.error = function(m) { #{messenger(params.sender_id, :error, `m`)} }`
            `console.info =  function(m) { #{messenger(params.sender_id, :info,  `m`)} }`
            begin
              message = `eval(#{params.string})`.inspect
              Response.run(target_id: params.sender_id, kind: :result, message: message || '')
            rescue Exception => e
              Response.run(target_id: params.sender_id, kind: :exception, message: e.to_s)
            ensure
              `console.warn =  cwarn`
              `console.log =   clog`
              `console.error = cerror`
              `console.info =  cinfo`
              nil
            end
          end
        end
        self
      end
      `window.hyperconsole = function() { Opal.Opal.$console() }`
      Hyperloop::Application::Boot.on_dispatch do
        @console ||= console if `window.HyperloopConsoleAutoStart`
      end
    end
  end
else
  module Hyperloop
    define_setting :console_auto_start, true

    module Console
      class Config
        include React::IsomorphicHelpers
        prerender_footer do |controller|
          "<script type='text/javascript'>\n"\
            "window.HyperloopConsoleAutoStart = #{!!Hyperloop.console_auto_start};\n"\
          "</script>\n"
        end
      end
    end

    ::Hyperloop::Engine.routes.append do
      Hyperloop.initialize_policies

      HyperloopController.class_eval do
        def opal_debug_console
          console_params = { application_window_id: params[:application_window_id], context: params[:context], title: params[:title] }
          render inline:
            "<!DOCTYPE html>\n"\
            "<html>\n"\
            "  <head>\n"\
            "    <title>Hyperloop Console Loading...</title>\n"\
            "    <%= csrf_meta_tags %>\n"\
            "    <%= stylesheet_link_tag    'hyper-console-client' %>\n"\
            "    <%= javascript_include_tag 'hyper-console-client.min.js' %>\n"\
            "    <%= javascript_include_tag 'action_cable' %>\n"\
            "  </head>\n"\
            "  <body>\n"\
            "    <%= react_component 'Hyperloop::Console::DebugConsole', #{console_params}, { prerender: false } %>\n"\
            "  </body>\n"\
            "</html>\n"
        end
      end
      match 'hyperloop-debug-console/:application_window_id', to: 'hyperloop#opal_debug_console', via: :get
    end
  end
end
