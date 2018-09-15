
# dummy up React::Config so it doesn't complain

module React
  module Config
    extend self
    def environment=(value)
      config[:environment] = value
    end

    def config
      @config ||= default_config
    end

    def default_config
      {
        environment: 'express'
      }
    end
  end
end
