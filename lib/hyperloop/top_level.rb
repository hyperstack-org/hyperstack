module Hyperloop

  class TopLevel
    def self.search_path
      @search_path ||= [Object]
    end

    def self.on_ready_mount(component, params = nil, element_query = nil)
      # this looks a bit odd but works across _all_ browsers, and no event handler mess
      # TODO: server rendering
      %x{
        function do_the_mount() { #{mount(component, params, element_query)} };
        function ready_fun() {
          /in/.test(document.readyState) ? setTimeout(ready_fun,5) : do_the_mount();
        };
        ready_fun();
      }
    end

    def self.mount(component, params = nil, element_query = nil)
      # TODO: server rendering
      if element_query.nil?
        if params.nil?
          params = {}
          element_query = 'div'
        elsif params.class == String
          element_query = params
          params = {}
        end
      end
      element = `document.body.querySelector(element_query)`
      `ReactDOM.render(#{React::RenderingContext.render(component, params).to_n}, element)`
    end

    def self.ujs_mount
      # TODO: implement mount using RailsUJS, for turbolinks and things
    end
  end
end
