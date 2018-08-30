# TODO this needs to be implemented as separate gem, not used for now, keep as reminder

require 'hyperstack/transport/version'
require 'hyper-transport'

if RUBY_ENGINE == 'opal'
  require 'hyperstack/transport/web_socket'
else
  Opal.append_path(__dir__.untaint) unless Opal.paths.include?(__dir__.untaint)
end