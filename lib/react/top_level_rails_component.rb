module React
  class TopLevelRailsComponent
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

      if params.component_name.start_with?('::')
        paths_searched << params.component_name.gsub(/^\:\:/, '')

        @component =
          begin
            params.component_name.gsub(/^\:\:/, '').split('::')
                  .inject(Module) { |scope, next_const| scope.const_get(next_const, false) }
          rescue
            nil
          end

        return @component if @component && @component.method_defined?(:render)
      else
        self.class.search_path.each do |path|
          # try each path + params.controller + params.component_name
          paths_searched << "#{path.name + '::' unless path == Module}"\
                            "#{params.controller}::#{params.component_name}"

          @component =
            begin
              [params.controller, params.component_name]
                .join('::').split('::')
                .inject(path) { |scope, next_const| scope.const_get(next_const, false) }
            rescue
              nil
            end

          return @component if @component && @component.method_defined?(:render)
        end

        self.class.search_path.each do |path|
          # then try each path + params.component_name
          paths_searched << "#{path.name + '::' unless path == Module}#{params.component_name}"
          @component =
            begin
              params.component_name.to_s.split('::')
                    .inject(path) { |scope, next_const| scope.const_get(next_const, false) }
            rescue
              nil
            end

          return @component if @component && @component.method_defined?(:render)
        end
      end

      @component = nil

      raise "Could not find component class '#{params.component_name}' "\
            "for params.controller '#{params.controller}' in any component directory. "\
            "Tried [#{paths_searched.join(', ')}]"
    end

    before_mount do
      TopLevelRailsComponent.event_history = Hash.new { |h, k| h[k] = [] }
      @render_params = params.render_params
      component.validator.rules.each do |name, rules|
        next unless rules[:type] == Proc

        TopLevelRailsComponent.event_history[name] = []
        @render_params[name] = lambda do |*args|
          TopLevelRailsComponent.event_history[name] << args
        end
      end
    end

    def render
      present component, @render_params
    end
  end
end
