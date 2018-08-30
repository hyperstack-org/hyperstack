require 'hyper-transport'

if RUBY_ENGINE == 'opal'
  require 'hyperstack/transport/http'
else
  Opal.append_path(__dir__.untaint) unless Opal.paths.include?(__dir__.untaint)
end
