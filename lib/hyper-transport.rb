require 'hyperloop/transport/version'
if RUBY_ENGINE != 'opal'
  Opal.append_path(__dir__.untaint) unless Opal.paths.include?(__dir__.untaint)
end
