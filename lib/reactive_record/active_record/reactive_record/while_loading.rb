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
    React::IsomorphicHelpers.log "ReactiveRecord.load exception raised during initial load: #{e}", :error
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
    React::IsomorphicHelpers.log "ReactiveRecord.load exception raised during retry: #{e}", :error
  end


  # Adds while_loading feature to React
  # to use attach a .while_loading handler to any element for example
  # div { "displayed if everything is loaded" }.while_loading { "displayed while I'm loading" }
  # the contents of the div will be switched (using javascript classes) depending on the state of contents of the first block

  # To notify React that something is loading use React::WhileLoading.loading!
  # once everything is loaded then do React::WhileLoading.loaded_at message (typically a time stamp just for debug purposes)

  class WhileLoading

    include React::IsomorphicHelpers

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
      React::State.has_observers?(self, :loaded_at)
    end

    prerender_footer do
      "<style>\n#{@css_to_preload}\n</style>".tap { @css_to_preload = ""}
    end

    if RUBY_ENGINE == 'opal'

      # +: I DONT THINK WE USE opal-jquery in this module anymore - require 'opal-jquery' if opal_client?
      # -: You think wrong. add_style_sheet uses the jQuery $, after_mount too, others too
      # -: I removed those references. Now you think right.

      include Hyperloop::Component::Mixin

      param :loading
      param :loaded_children
      param :loading_children
      param :element_type
      param :element_props
      param :display, default: ''

      class << self

        def loading?
          @is_loading
        end

        def loading!
          React::RenderingContext.waiting_on_resources = true
          React::State.get_state(self, :loaded_at)
          # this was moved to where the fetch is actually pushed on to the fetch array in isomorphic base
          # React::State.set_state(self, :quiet, false)
          @is_loading = true
        end

        def loaded_at(loaded_at)
          React::State.set_state(self, :loaded_at, loaded_at)
          @is_loading = false
        end

        def quiet?
          React::State.get_state(self, :quiet)
        end

        def page_loaded?
          React::State.get_state(self, :page_loaded)
        end

        def quiet!
          React::State.set_state(self, :quiet, true)
          after(1) { React::State.set_state(self, :page_loaded, true) } unless on_opal_server? or @page_loaded
          @page_loaded = true
        end

        def add_style_sheet
          # directly assigning the code to the variable triggers a opal 0.10.5 compiler bug.
          unless @style_sheet_added
            %x{
              var style_el = document.createElement("style");
              style_el.setAttribute("type", "text/css");
              style_el.innerHTML = ".reactive_record_is_loading > .reactive_record_show_when_loaded { display: none; }\n" +
                                   ".reactive_record_is_loaded > .reactive_record_show_while_loading { display: none; }";
              document.head.append(style_el);
            }
            @style_sheet_added = true
          end
        end

      end

      before_mount do
        @uniq_id = WhileLoading.get_next_while_loading_counter
        WhileLoading.preload_css(
          ".reactive_record_while_loading_container_#{@uniq_id} > :nth-child(1n+#{params.loaded_children.count+1}) {\n"+
          "  display: none;\n"+
          "}\n"
        )
      end

      after_mount do
        @waiting_on_resources = params.loading
        WhileLoading.add_style_sheet
        node = dom_node
        %x{
          var nodes = node.querySelectorAll(':nth-child(-1n+'+#{params.loaded_children.count}+')');
          nodes.forEach(
            function(current_node, current_index, list_obj) {
              if (current_node.className.indexOf('reactive_record_show_when_loaded') === -1) {
                current_node.className = current_node.className + ' reactive_record_show_when_loaded';
              }
            }
          );
          nodes = node.querySelectorAll(':nth-child(1n+'+#{params.loaded_children.count+1}+')');
          nodes.forEach(
            function(current_node, current_index, list_obj) {
              if (current_node.className.indexOf('reactive_record_show_while_loading') === -1) {
                current_node.className = current_node.className + ' reactive_record_show_while_loading';
              }
            }
          );
        }
      end

      after_update do
        @waiting_on_resources = params.loading
      end

      def render
        props = params.element_props.dup
        classes = [props[:class], props[:className], "reactive_record_while_loading_container_#{@uniq_id}"].compact.join(" ")
        props.merge!({
          "data-reactive_record_while_loading_container_id" => @uniq_id,
          "data-reactive_record_enclosing_while_loading_container_id" => @uniq_id,
          class: classes
        })
        React.create_element(params.element_type[0], props) do
          params.loaded_children + params.loading_children
        end.tap { |e| e.waiting_on_resources = params.loading }
      end

    end

  end

end

module React

  class Element

    def while_loading(display = "", &loading_display_block)
      loaded_children = []
      loaded_children = block.call.dup if block
      if display.respond_to? :as_node
        display = display.as_node
        loading_display_block = lambda { display.render }
      elsif !loading_display_block
        loading_display_block = lambda { display }
      end
      loading_children = RenderingContext.build do |buffer|
        result = loading_display_block.call
        result = result.to_s if result.try :acts_as_string?
        result.span.tap { |e| e.waiting_on_resources = RenderingContext.waiting_on_resources } if result.is_a? String
        buffer.dup
      end

     new_element = React.create_element(
        ReactiveRecord::WhileLoading,
        loading: waiting_on_resources,
        loading_children: loading_children,
        loaded_children: loaded_children,
        element_type: [type],
        element_props: properties)

      RenderingContext.replace(self, new_element)
    end

    def hide_while_loading
      while_loading
    end

  end
end

if RUBY_ENGINE == 'opal'
  module Hyperloop
    class Component
      module Mixin

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
end
