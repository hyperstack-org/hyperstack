module Hyperstack
  module Internal
    module Component
      class TopLevelRailsComponent
        include Hyperstack::Component

        def self.search_path
          @search_path ||= [Object]
        end

        export_component

        param :component_name
        param :controller
        param :render_params

        backtrace :off

        def self.allow_deprecated_render_definition?
          true
        end

        def render
          top_level_render
        end

        def top_level_render
          paths_searched = []
          component = nil
          if @ComponentName.start_with?('::')
            # if absolute path of component is given, look it up and fail if not found
            paths_searched << @ComponentName
            component = begin
                          Object.const_get(@ComponentName)
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
              paths_searched << "#{scope.name}::#{@Controller}::#{@ComponentName}"
              component = begin
                            scope.const_get(@Controller, false).const_get(@ComponentName, false)
                          rescue NameError
                            nil
                          end
              break if component != nil
            end
            unless component
              self.class.search_path.each do |scope|
                paths_searched << "#{scope.name}::#{@ComponentName}"
                component = begin
                              scope.const_get(@ComponentName, false)
                            rescue NameError
                              nil
                            end
                break if component != nil
              end
            end
          end
          return RenderingContext.render(component, @RenderParams) if component && component.method_defined?(:render)
          raise "Could not find component class '#{@ComponentName}' for @Controller '#{@Controller}' in any component directory. Tried [#{paths_searched.join(", ")}]"
        end
      end
    end
  end
end

class Module
  def add_to_react_search_path(replace_search_path = nil)
    if replace_search_path
      Hyperstack::Internal::Component::TopLevelRailsComponent.search_path = [self]
    elsif !Hyperstack::Internal::Component::TopLevelRailsComponent.search_path.include? self
      Hyperstack::Internal::Component::TopLevelRailsComponent.search_path << self
    end
  end
end

module Components
  add_to_react_search_path
end
