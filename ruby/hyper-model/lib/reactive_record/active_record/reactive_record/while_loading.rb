module HyperMesh
  def self.load(&block)
    ReactiveRecord.load(&block)
  end
end

module ReactiveRecord

  # will repeatedly execute the block until it is loaded
  # immediately returns a promise that will resolve once the block is loaded

  def self.load(&block)
    promise = Promise.new
    @load_stack ||= []
    @load_stack << @loads_pending
    @loads_pending = nil
    result = block.call.itself
    if @loads_pending
      @blocks_to_load ||= []
      @blocks_to_load << [Base.current_fetch_id, promise, block]
    else
      promise.resolve result
    end
    @loads_pending = @load_stack.pop
    promise
  rescue Exception => e
    Hyperstack::Component::IsomorphicHelpers.log "ReactiveRecord.load exception raised during initial load: #{e}", :error
  end

  def self.loads_pending!
    @loads_pending = true
  end

  def self.check_loads_pending
    if @loads_pending
      if Base.pending_fetches.count > 0
        true
      else  # this happens when for example loading foo.x results in somebody looking at foo.y while foo.y is still being loaded
        ReactiveRecord::WhileLoading.loaded_at Base.current_fetch_id
        ReactiveRecord::WhileLoading.quiet!
        false
      end
    end
  end

  def self.run_blocks_to_load(fetch_id, failure = nil)
    if @blocks_to_load
      blocks_to_load_now = @blocks_to_load.select { |data| data.first == fetch_id }
      @blocks_to_load = @blocks_to_load.reject { |data| data.first == fetch_id }
      @load_stack ||= []
      blocks_to_load_now.each do |data|
        id, promise, block = data
        @load_stack << @loads_pending
        @loads_pending = nil
        result = block.call(failure)
        if check_loads_pending && !failure
          @blocks_to_load << [Base.current_fetch_id, promise, block]
        else
          promise.resolve result
        end
        @loads_pending = @load_stack.pop
      end
    end
  rescue Exception => e
    Hyperstack::Component::IsomorphicHelpers.log "ReactiveRecord.load exception raised during retry: #{e}", :error
  end


  # Adds while_loading feature to React
  # to use attach a .while_loading handler to any element for example
  # div { "displayed if everything is loaded" }.while_loading { "displayed while I'm loading" }
  # the contents of the div will be switched (using javascript classes) depending on the state of contents of the first block

  # To notify React that something is loading use React::WhileLoading.loading!
  # once everything is loaded then do React::WhileLoading.loaded_at message (typically a time stamp just for debug purposes)

  #   class WhileLoading
  #
  #     include Hyperstack::Component::IsomorphicHelpers
  #
  #     before_first_mount do
  #       @css_to_preload = ""
  #       @while_loading_counter = 0
  #     end
  #
  #     def self.get_next_while_loading_counter
  #       @while_loading_counter += 1
  #     end
  #
  #     def self.preload_css(css)
  #       @css_to_preload += "#{css}\n"
  #     end
  #
  #     def self.has_observers?
  #       Hyperstack::Internal::State::Variable.observed?(self, :loaded_at)
  #     end
  #
  #     class << self
  #       alias :observed? :has_observers?
  #     end
  #
  #     prerender_footer do
  #       "<style>\n#{@css_to_preload}\n</style>".tap { @css_to_preload = ""}
  #     end
  #
  #     if RUBY_ENGINE == 'opal'
  #
  #       # +: I DONT THINK WE USE opal-jquery in this module anymore - require 'opal-jquery' if opal_client?
  #       # -: You think wrong. add_style_sheet uses the jQuery $, after_mount too, others too
  #       # -: I removed those references. Now you think right.
  #
  #       include Hyperstack::Component
  #
  #       param :render_original_child
  #       param :loading
  #
  #       class << self
  #
  #         def loading?
  #           @is_loading
  #         end
  #
  #         def loading!
  #           Hyperstack::Internal::Component::RenderingContext.waiting_on_resources = true
  #           Hyperstack::Internal::State::Variable.get(self, :loaded_at)
  #           # this was moved to where the fetch is actually pushed on to the fetch array in isomorphic base
  #           # Hyperstack::Internal::State::Variable.set(self, :quiet, false)
  #           @is_loading = true
  #         end
  #
  #         def loaded_at(loaded_at)
  #           Hyperstack::Internal::State::Variable.set(self, :loaded_at, loaded_at)
  #           @is_loading = false
  #         end
  #
  #         def quiet?
  #           Hyperstack::Internal::State::Variable.get(self, :quiet)
  #         end
  #
  #         def page_loaded?
  #           Hyperstack::Internal::State::Variable.get(self, :page_loaded)
  #         end
  #
  #         def quiet!
  #           Hyperstack::Internal::State::Variable.set(self, :quiet, true)
  #           after(1) { Hyperstack::Internal::State::Variable.set(self, :page_loaded, true) } unless on_opal_server? or @page_loaded
  #           @page_loaded = true
  #         end
  #
  #         def add_style_sheet
  #           # directly assigning the code to the variable triggers a opal 0.10.5 compiler bug.
  #           unless @style_sheet_added
  #             %x{
  #               var style_el = document.createElement("style");
  #               style_el.setAttribute("type", "text/css");
  #               style_el.innerHTML = ".reactive_record_is_loading > .reactive_record_show_when_loaded { display: none !important; }\n" +
  #                                    ".reactive_record_is_loaded > .reactive_record_show_while_loading { display: none !important; }";
  #               document.head.append(style_el);
  #             }
  #             @style_sheet_added = true
  #           end
  #         end
  #
  #       end
  #
  #       def after_mount_and_update
  #         @waiting_on_resources = @Loading
  #         node = dom_node
  #         %x{
  #           Array.from(node.children).forEach(
  #             function(current_node, current_index, list_obj) {
  #               if (current_index > 0 && current_node.className.indexOf('reactive_record_show_when_loaded') === -1) {
  #                 current_node.className = current_node.className + ' reactive_record_show_when_loaded';
  #               } else if (current_index == 0 && current_node.className.indexOf('reactive_record_show_while_loading') === -1) {
  #                 current_node.className = current_node.className + ' reactive_record_show_while_loading';
  #               }
  #             }
  #           );
  #         }
  #         nil
  #       end
  #
  #       before_mount do
  #         @uniq_id = WhileLoading.get_next_while_loading_counter
  #         WhileLoading.preload_css(
  #           ":not(.reactive_record_is_loading).reactive_record_while_loading_container_#{@uniq_id} > :nth-child(1) {\n"+
  #           "  display: none;\n"+
  #           "}\n"
  #         )
  #       end
  #
  #       after_mount do
  #         WhileLoading.add_style_sheet
  #         after_mount_and_update
  #       end
  #
  #       after_update :after_mount_and_update
  #
  #       render do
  #         @RenderOriginalChild.call(@uniq_id)
  #       end
  #
  #     end
  #
  #   end
  #
  # end
  #
  # module Hyperstack
  #   module Component
  #
  #     class Element
  #
  #       def while_loading(display = "", &loading_display_block)
  #         original_block = block || -> () {}
  #
  #         if display.respond_to? :as_node
  #           display = display.as_node
  #           block = lambda { display.render; instance_eval(&original_block) }
  #         elsif !loading_display_block
  #           block = lambda { display; instance_eval(&original_block) }
  #         else
  #           block = ->() { instance_eval(&loading_display_block); instance_eval(&original_block) }
  #         end
  #          loading_child = Internal::Component::RenderingContext.build do |buffer|
  #            Hyperstack::Internal::Component::RenderingContext.render(:span, key: 1, &loading_display_block) #{ to_s }
  #            buffer.dup
  #          end
  #         children = `#{@native}.props.children.slice(0)`
  #         children.unshift(loading_child[0].instance_eval { @native })
  #         @native = `React.cloneElement(#{@native}, #{@properties.shallow_to_n}, #{children})`
  #        render_original_child = lambda do |uniq_id|
  #          classes = [
  #            @properties[:class], @properties[:className],
  #            "reactive_record_while_loading_container_#{uniq_id}"
  #          ].compact.join(' ')
  #          @properties.merge!({
  #            "data-reactive_record_while_loading_container_id" => uniq_id,
  #            "data-reactive_record_enclosing_while_loading_container_id" => uniq_id,
  #            className: classes
  #          })
  #          @native = `React.cloneElement(#{@native}, #{@properties.shallow_to_n})`
  #          render
  #        end
  #        delete
  #        ReactAPI.create_element(
  #           ReactiveRecord::WhileLoading,
  #           loading: waiting_on_resources,
  #           render_original_child: render_original_child)
  #       end
  #
  #       def hide_while_loading
  #         while_loading
  #       end
  #
  #     end
  #   end
  # end
  #


  class WhileLoading

    include Hyperstack::Component::IsomorphicHelpers

    before_first_mount do
      @css_to_preload = ""
      @while_loading_counter = 0
    end

    def self.get_next_while_loading_counter
      @while_loading_counter += 1
    end

    def self.preload_css(css)
      @css_to_preload += "#{css}\n"
    end

    def self.has_observers?
      Hyperstack::Internal::State::Variable.observed?(self, :loaded_at)
    end

    class << self
      alias :observed? :has_observers?
    end

    prerender_footer do
      "<style>\n#{@css_to_preload}\n</style>".tap { @css_to_preload = ""}
    end

    if RUBY_ENGINE == 'opal'

      # +: I DONT THINK WE USE opal-jquery in this module anymore - require 'opal-jquery' if opal_client?
      # -: You think wrong. add_style_sheet uses the jQuery $, after_mount too, others too
      # -: I removed those references. Now you think right.

      include Hyperstack::Component

      param :loading
      param :loaded_children
      param :loading_children
      param :element_type
      param :element_props
      others :other_props
      param :display, default: ''

      class << self

        def loading?
          @is_loading
        end

        def loading!
          Hyperstack::Internal::Component::RenderingContext.waiting_on_resources = true
          Hyperstack::Internal::State::Variable.get(self, :loaded_at)
          # this was moved to where the fetch is actually pushed on to the fetch array in isomorphic base
          # Hyperstack::Internal::State::Variable.set(self, :quiet, false)
          @is_loading = true
        end

        def loaded_at(loaded_at)
          Hyperstack::Internal::State::Variable.set(self, :loaded_at, loaded_at)
          @is_loading = false
        end

        def quiet?
          Hyperstack::Internal::State::Variable.get(self, :quiet)
        end

        def page_loaded?
          Hyperstack::Internal::State::Variable.get(self, :page_loaded)
        end

        def quiet!
          Hyperstack::Internal::State::Variable.set(self, :quiet, true)
          after(1) { Hyperstack::Internal::State::Variable.set(self, :page_loaded, true) } unless on_opal_server? or @page_loaded
          @page_loaded = true
        end

        def add_style_sheet
          # directly assigning the code to the variable triggers a opal 0.10.5 compiler bug.
          unless @style_sheet_added
            %x{
              var style_el = document.createElement("style");
              style_el.setAttribute("type", "text/css");
              style_el.innerHTML = ".reactive_record_is_loading > .reactive_record_show_when_loaded { display: none !important; }\n" +
                                   ".reactive_record_is_loaded > .reactive_record_show_while_loading { display: none !important; }";
              document.head.append(style_el);
            }
            @style_sheet_added = true
          end
        end

      end

      def after_mount_and_update
        @waiting_on_resources = @Loading
        node = dom_node
        %x{
          Array.from(node.children).forEach(
            function(current_node, current_index, list_obj) {
              if (current_index > 0 && current_node.className.indexOf('reactive_record_show_when_loaded') === -1) {
                current_node.className = current_node.className + ' reactive_record_show_when_loaded';
              } else if (current_index == 0 && current_node.className.indexOf('reactive_record_show_while_loading') === -1) {
                current_node.className = current_node.className + ' reactive_record_show_while_loading';
              }
            }
          );
        }
        nil
      end

      before_mount do
        @uniq_id = WhileLoading.get_next_while_loading_counter
        WhileLoading.preload_css(
          ":not(.reactive_record_is_loading).reactive_record_while_loading_container_#{@uniq_id} > :nth-child(1) {\n"+
          "  display: none;\n"+
          "}\n"
        )
      end

      after_mount do
        WhileLoading.add_style_sheet
        after_mount_and_update
      end

      after_update :after_mount_and_update

      render do
        # return ReactAPI.create_element(@ElementType[0], @ElementProps.dup) do
        #   @LoadedChildren
        # end
        props = @ElementProps.dup
        classes = [
          props[:class], props[:className],
          @OtherProps.delete(:class), @OtherProps.delete(:className),
          "reactive_record_while_loading_container_#{@uniq_id}"
        ].compact.join(" ")
        props.merge!({
          "data-reactive_record_while_loading_container_id" => @uniq_id,
          "data-reactive_record_enclosing_while_loading_container_id" => @uniq_id,
          class: classes
        })
        props.merge!(@OtherProps)
        ReactAPI.create_element(@ElementType[0], props) do
          @LoadingChildren + @LoadedChildren
        end.tap { |e| e.waiting_on_resources = @Loading }
      end

    end

  end

end

module Hyperstack
  module Component

    class Element

      def while_loading(display = "", &loading_display_block)
        loaded_children = []
        loaded_children = block.call.dup if block
        if loaded_children.last.is_a? String
          loaded_children <<
            Hyperstack::Internal::Component::ReactWrapper.create_element(:span) { loaded_children.pop }
        end
        if display.respond_to? :as_node
          display = display.as_node
          loading_display_block = lambda { display.render }
        elsif !loading_display_block
          loading_display_block = lambda { display }
        end
        loading_children = Internal::Component::RenderingContext.build do |buffer|
          Hyperstack::Internal::Component::RenderingContext.render(:span, &loading_display_block) #{ to_s }
          buffer.dup
        end
       as_node
       new_element = ReactAPI.create_element(
          ReactiveRecord::WhileLoading,
          loading: waiting_on_resources,
          loading_children: loading_children,
          loaded_children: loaded_children,
          element_type: [type],
          element_props: properties)

        #Internal::Component::RenderingContext.replace(self, new_element)
      end

      def hide_while_loading
        while_loading
      end

    end
  end
end

if RUBY_ENGINE == 'opal'
  module Hyperstack
    module Component

      def quiet?
        Hyperstack::Internal::State::Variable.get(ReactiveRecord::WhileLoading, :quiet)
      end

      alias_method :original_component_did_mount, :component_did_mount

      def component_did_mount(*args)
        original_component_did_mount(*args)
        reactive_record_link_to_enclosing_while_loading_container
        reactive_record_link_set_while_loading_container_class
      end

      alias_method :original_component_did_update, :component_did_update

      def component_did_update(*args)
        original_component_did_update(*args)
        reactive_record_link_set_while_loading_container_class
      end

      # This is required to support legacy browsers (Internet Explorer 9+)
      # https://developer.mozilla.org/en-US/docs/Web/API/Element/closest#Polyfill
      `
      if (typeof(Element) != 'undefined' && !Element.prototype.matches) {
        Element.prototype.matches = Element.prototype.msMatchesSelector ||
                                    Element.prototype.webkitMatchesSelector;
      }

      if (typeof(Element) != 'undefined' && !Element.prototype.closest) {
        Element.prototype.closest = function(s) {
          var el = this;

          do {
            if (el.matches(s)) return el;
            el = el.parentElement || el.parentNode;
          } while (el !== null && el.nodeType === 1);
          return null;
        };
      }
      `

      def reactive_record_link_to_enclosing_while_loading_container
        # Call after any component mounts - attaches the containers loading id to this component
        # Fyi, the while_loading container is responsible for setting its own link to itself
        node = dom_node
        %x{
            if (typeof node === "undefined" || node === null) return;
            var node_wl_attr = node.getAttribute('data-reactive_record_enclosing_while_loading_container_id');
            if (node_wl_attr === null || node_wl_attr === "") {
              var while_loading_container = node.closest('[data-reactive_record_while_loading_container_id]');
              if (while_loading_container !== null) {
                var container_id = while_loading_container.getAttribute('data-reactive_record_while_loading_container_id');
                node.setAttribute('data-reactive_record_enclosing_while_loading_container_id', container_id);
              }
            }
          }
      end

      def reactive_record_link_set_while_loading_container_class
        node = dom_node
        loading = (waiting_on_resources ? `true` : `false`)
        %x{
            if (typeof node === "undefined" || node === null) return;
            var while_loading_container_id = node.getAttribute('data-reactive_record_while_loading_container_id');
            if (#{!self.is_a?(ReactiveRecord::WhileLoading)} && while_loading_container_id !== null && while_loading_container_id !== "") {
              return;
            }
            var enc_while_loading_container_id = node.getAttribute('data-reactive_record_enclosing_while_loading_container_id');
            if (enc_while_loading_container_id !== null && enc_while_loading_container_id !== "") {
              var while_loading_container = document.body.querySelector('[data-reactive_record_while_loading_container_id="'+enc_while_loading_container_id+'"]');
              if (loading) {
                node.className = node.className.replace(/reactive_record_is_loaded/g, '').replace(/  /g, ' ');
                if (node.className.indexOf('reactive_record_is_loading') === -1) {
                  node.className = node.className + ' reactive_record_is_loading';
                }
                if (while_loading_container !== null) {
                  while_loading_container.className = while_loading_container.className.replace(/reactive_record_is_loaded/g, '').replace(/  /g, ' ');
                  if (while_loading_container.className.indexOf('reactive_record_is_loading') === -1) {
                    while_loading_container.className = while_loading_container.className + ' reactive_record_is_loading';
                  }
                }
              } else if (node.className.indexOf('reactive_record_is_loaded') === -1) {
                if (while_loading_container_id === null || while_loading_container_id === "") {
                  node.className = node.className.replace(/reactive_record_is_loading/g, '').replace(/  /g, ' ');
                  if (node.className.indexOf('reactive_record_is_loaded') === -1) {
                    node.className = node.className + ' reactive_record_is_loaded';
                  }
                }
                if (while_loading_container.className.indexOf('reactive_record_is_loaded') === -1) {
                  var loading_children = while_loading_container.querySelectorAll('[data-reactive_record_enclosing_while_loading_container_id="'+enc_while_loading_container_id+'"].reactive_record_is_loading');
                  if (loading_children.length === 0) {
                    while_loading_container.className = while_loading_container.className.replace(/reactive_record_is_loading/g, '').replace(/  /g, ' ');
                    if (while_loading_container.className.indexOf('reactive_record_is_loaded') === -1) {
                      while_loading_container.className = while_loading_container.className + ' reactive_record_is_loaded';
                    }
                  }
                }
              }
            }
          }
      end
    end
  end
end
