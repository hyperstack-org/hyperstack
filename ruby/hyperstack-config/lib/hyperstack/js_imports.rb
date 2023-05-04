module Hyperstack
  class << self
    def js_import(value, client_only: nil, server_only: nil, defines:)
      defines = [*defines]
      if RUBY_ENGINE != 'opal'
        import(value, client_only: client_only, server_only: server_only, js_import: true)
      else
        on_server = `typeof Opal.global.document === 'undefined'`
        return if (server_only && !on_server) || (client_only && on_server)
        defines.each do |name|
          next unless `Opal.global['#{name}'] === undefined`
          raise "The package #{name} was not found. Add it to the webpack "\
                "#{client_only ? 'client_only.js' : 'client_and_server.js'} manifest."
        end
      end
    end
  end
end
