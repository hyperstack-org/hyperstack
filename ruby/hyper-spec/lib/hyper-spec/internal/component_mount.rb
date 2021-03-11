module HyperSpec
  module Internal
    module ComponentMount
      private

      TEST_CODE_KEY = 'hyper_spec_prerender_test_code.js'.freeze

      # rubocop:disable Metrics/MethodLength
      def add_block_with_helpers(component_name, opts, block)
        return unless block || @_hyperspec_private_client_code || component_name.nil?

        block_with_helpers = <<-RUBY
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
          #{test_dummy}
          #{@_hyperspec_private_client_code}
          #{Unparser.unparse(Parser::CurrentRuby.parse(block.source).children.last) if block}
        RUBY
        @_hyperspec_private_client_code = nil
        opts[:code] = opal_compile(block_with_helpers)
      end
      # rubocop:enable Metrics/MethodLength

      def build_test_url_for(controller = nil, ping = nil)
        id = ping ? 'ping' : Controller.test_id
        "/#{route_root_for(controller)}/#{id}"
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

      def internal_mount(component_name, params, opts, &block)
        # TODO:  refactor this
        test_url = build_test_url_for(opts.delete(:controller))
        add_block_with_helpers(component_name, opts, block)
        send_params_to_controller_via_cache(test_url, component_name, params, opts)
        setup_prerendering(opts)
        page.instance_variable_set('@hyper_spec_mounted', false)
        visit test_url
        wait_for_ajax unless opts[:no_wait]
        page.instance_variable_set('@hyper_spec_mounted', true)
        Lolex.init(self, client_options[:time_zone], client_options[:clock_resolution])
      end

      def prerendering?(opts)
        %i[both server_only].include?(opts[:render_on])
      end

      def send_params_to_controller_via_cache(test_url, component_name, params, opts)
        component_name ||= 'Hyperstack::Internal::Component::TestDummy' if test_dummy
        Controller.cache_write(
          test_url,
          [component_name, params, @_hyperspec_private_html_block, opts]
        )
        @_hyperspec_private_html_block = nil
      end

      # test_code_key = "hyper_spec_prerender_test_code.js"
      # if defined? ::Hyperstack::Component
      #   @@original_server_render_files ||= ::Rails.configuration.react.server_renderer_options[:files]
      #   if opts[:render_on] == :both || opts[:render_on] == :server_only
      #     unless opts[:code].blank?
      #       ComponentTestHelpers.cache_write(test_code_key, opts[:code])
      #       ::Rails.configuration.react.server_renderer_options[:files] = @@original_server_render_files + [test_code_key]
      #       ::React::ServerRendering.reset_pool # make sure contexts are reloaded so they dont use code from cache, as the rails filewatcher doesnt look for cache changes
      #     else
      #       ComponentTestHelpers.cache_delete(test_code_key)
      #       ::Rails.configuration.react.server_renderer_options[:files] = @@original_server_render_files
      #       ::React::ServerRendering.reset_pool # make sure contexts are reloaded so they dont use code from cache, as the rails filewatcher doesnt look for cache changes
      #     end
      #   end
      # end

      def setup_prerendering(opts)
        return unless defined?(::Hyperstack::Component) && prerendering?(opts)

        @@original_server_render_files ||= ::Rails.configuration.react.server_renderer_options[:files]
        ::Rails.configuration.react.server_renderer_options[:files] = @@original_server_render_files
        if opts[:code].blank?
          Controller.cache_delete(TEST_CODE_KEY)
        else
          Controller.cache_write(TEST_CODE_KEY, opts[:code])
          ::Rails.configuration.react.server_renderer_options[:files] += [TEST_CODE_KEY]
        end
        ::React::ServerRendering.reset_pool
        # make sure contexts are reloaded so they dont use code from cache, as the rails filewatcher
        # doesnt look for cache changes
      end

      def test_dummy
        return unless defined? ::Hyperstack::Component

        <<-RUBY
          class Hyperstack::Internal::Component::TestDummy
            include Hyperstack::Component
            render {}
          end
        RUBY
      end
    end
  end
end
