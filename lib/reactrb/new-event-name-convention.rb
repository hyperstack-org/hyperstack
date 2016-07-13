# rubocop:disable Style/FileName
# require 'reactrb/new-event-name-convention' to remove missing param declaration "_onXXXX"
if RUBY_ENGINE == 'opal'
  # removes generation of the deprecated "_onXXXX" event param syntax
  module React
    class Element
      def merge_deprecated_component_event_prop!(event_name)
      end
    end
  end
end
