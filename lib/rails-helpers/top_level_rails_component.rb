module React
  class TopLevelRailsComponent
    include Hyperloop::Component::Mixin

    def self.search_path
      @search_path ||= [Object]
    end

    export_component

    param :component_name
    param :controller
    param :render_params

    backtrace :off

    def render
      paths_searched = []
      component = nil
      if params.component_name.start_with?('::')
        # if absolute path of component is given, look it up and fail if not found
        paths_searched << params.component_name
        component = begin
                      Object.const_get(params.component_name)
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
          paths_searched << "#{scope.name}::#{params.controller}::#{params.component_name}"
          component = begin
                        scope.const_get(params.controller, false).const_get(params.component_name, false)
                      rescue NameError
                        nil
                      end
          break if component != nil
        end
        unless component
          self.class.search_path.each do |scope|
            paths_searched << "#{scope.name}::#{params.component_name}"
            component = begin
                          scope.const_get(params.component_name, false)
                        rescue NameError
                          nil
                        end
            break if component != nil
          end
        end
      end
      return React::RenderingContext.render(component, params.render_params) if component && component.method_defined?(:render)
      raise "Could not find component class '#{params.component_name}' for params.controller '#{params.controller}' in any component directory. Tried [#{paths_searched.join(", ")}]"
    end
  end
end

class Module
  def add_to_react_search_path(replace_search_path = nil)
    if replace_search_path
      React::TopLevelRailsComponent.search_path = [self]
    elsif !React::TopLevelRailsComponent.search_path.include? self
      React::TopLevelRailsComponent.search_path << self
    end
  end
end

module Components
  add_to_react_search_path
end
