

if RUBY_ENGINE == 'opal'
  if `window.React === undefined || window.React.version === undefined`
    raise "No React.js Available\n\n"\
          "React.js must be defined before requiring 'reactrb'\n"\
          "'reactrb' has been tested with react v13, v14, and v15.\n\n"\
          "IF USING 'react-rails':\n"\
          "   add 'require \"react\"' immediately before the 'require \"reactive-ruby\" "\
              "directive in 'views/components.rb'.\n"\
          "IF USING WEBPACK:\n"\
          "   add 'react' to your webpack manifest.\n"\
          "OTHERWISE TO GET THE LATEST TESTED VERSION\n"\
          "   add 'require \"react-latest\"' immediately before the require of 'reactrb',\n"\
          "OR TO USE A SPECIFIC VERSION\n"\
          "   add 'require \"react-v1x\"' immediately before the require of 'reactrb'."
  end
  require 'react/hash'
  require 'react/top_level'
  require 'react/observable'
  require 'react/component'
  require 'react/component/dsl_instance_methods'
  require 'react/component/should_component_update'
  require 'react/component/tags'
  require 'react/component/base'
  require 'react/element'
  require 'react/event'
  require 'react/api'
  require 'react/validator'
  require 'react/rendering_context'
  require 'react/state'
  require 'reactive-ruby/isomorphic_helpers'
  require 'rails-helpers/top_level_rails_component'
  require 'reactive-ruby/version'

else
  require 'opal'
  require 'opal-browser'
  # rubocop:disable Lint/HandleExceptions
  begin
    require 'opal-jquery'
  rescue LoadError
  end
  # rubocop:enable Lint/HandleExceptions
  require 'opal-activesupport'
  require 'reactive-ruby/version'
  require 'reactive-ruby/rails' if defined?(Rails)
  require 'reactive-ruby/isomorphic_helpers'
  require 'reactive-ruby/serializers'

  Opal.append_path File.expand_path('../', __FILE__).untaint
  Opal.append_path File.expand_path('../sources/', __FILE__).untaint
end
