module Hyperloop

  class TopLevel
    def self.search_path
      @search_path ||= [Object]
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
      # TODO: implement mount using RailsUJS
    end
  end
end
