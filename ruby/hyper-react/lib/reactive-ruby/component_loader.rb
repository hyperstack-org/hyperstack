module ReactiveRuby
  class ComponentLoader
    attr_reader :v8_context
    private :v8_context

    def initialize(v8_context)
      unless v8_context
        raise ArgumentError.new('Could not obtain ExecJS runtime context')
      end
      @v8_context = v8_context
    end

    def load(file = components)
      return true if loaded?
      !!v8_context.eval(opal(file))
    end

    def load!(file = components)
      return true if loaded?
      self.load(file)
    ensure
      raise "No HyperReact components found in #{components}" unless loaded?
    end

    def loaded?
      !!v8_context.eval('Opal.React !== undefined')
    rescue ::ExecJS::Error
      false
    end

    private

    def components
      opts = ::Rails.configuration.react.server_renderer_options
      return opts[:files].first.gsub(/.js$/,'') if opts && opts[:files]
      'components'
    end

    def opal(file)
      Opal::Sprockets.load_asset(file)
    end
  end
end
