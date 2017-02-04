

if RUBY_ENGINE == 'opal'
  if `Opal.global.React === undefined || Opal.global.React.version === undefined`
    raise [
      "No React.js Available",
      "",
      "A global `React` must be defined before requiring 'hyper-react'",
      "",
      "To USE THE BUILT-IN SOURCE: ",
      "   add 'require \"react/react-source\"' immediately before the 'require \"hyper-react\" directive.",
      "IF USING WEBPACK:",
      "   add 'react' to your webpack manifest."
    ].join("\n")
  end
  require 'react/hash'
  require 'react/top_level'
  require 'react/observable'
  require 'react/validator'
  require 'react/component'
  require 'react/component/dsl_instance_methods'
  require 'react/component/should_component_update'
  require 'react/component/tags'
  require 'react/component/base'
  require 'react/element'
  require 'react/event'
  require 'react/api'
  require 'react/rendering_context'
  require 'react/state'
  require 'react/object'
  require "react/ext/opal-jquery/element"
  require 'reactive-ruby/isomorphic_helpers'
  require 'rails-helpers/top_level_rails_component'
  require 'reactive-ruby/version'

else
  require 'opal'
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
  require "react/react-source"
end
