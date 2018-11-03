module Hyperstack
  module Internal
    module Component
      class TopLevelRailsComponent

        # original class declares these params:
        # param :component_name
        # param :controller
        # param :render_params

        class << self
          attr_accessor :event_history

          def callback_history_for(proc_name)
            event_history[proc_name]
          end

          def last_callback_for(proc_name)
            event_history[proc_name].last
          end

          def clear_callback_history_for(proc_name)
            event_history[proc_name] = []
          end

          def event_history_for(event_name)
            event_history["_on#{event_name.event_camelize}"]
          end

          def last_event_for(event_name)
            event_history["_on#{event_name.event_camelize}"].last
          end

          def clear_event_history_for(event_name)
            event_history["_on#{event_name.event_camelize}"] = []
          end
        end

        def component
          return @component if @component
          paths_searched = []
          component = nil
          if @component_name.start_with?('::')
            # if absolute path of component is given, look it up and fail if not found
            paths_searched << @component_name
            component = begin
                          Object.const_get(@component_name)
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
              paths_searched << "#{scope.name}::#{@controller}::#{@component_name}"
              component = begin
                            scope.const_get(@controller, false).const_get(@component_name, false)
                          rescue NameError
                            nil
                          end
              break if component != nil
            end
            unless component
              self.class.search_path.each do |scope|
                paths_searched << "#{scope.name}::#{@component_name}"
                component = begin
                              scope.const_get(@component_name, false)
                            rescue NameError
                              nil
                            end
                break if component != nil
              end
            end
          end
          @component = component
          return @component if @component && @component.method_defined?(:render)
          raise "Could not find component class '#{@component_name}' for @controller '#{@controller}' in any component directory. Tried [#{paths_searched.join(", ")}]"
        end

        before_mount do
          TopLevelRailsComponent.event_history = Hash.new { |h, k| h[k] = [] }
          component.validator.rules.each do |name, rules|
            next unless rules[:type] == Proc

            TopLevelRailsComponent.event_history[name] = []
            @render_params[name] = lambda do |*args|
              TopLevelRailsComponent.event_history[name] << args
            end
          end
        end

        def render
          Hyperstack::Internal::Component::RenderingContext.render(component, @render_params)
        end
      end
    end
  end
end
