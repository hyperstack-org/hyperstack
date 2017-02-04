if RUBY_ENGINE != 'opal'
  require "react/config/server"
else
  require "react/config/client"
end
