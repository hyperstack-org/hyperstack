module React
  module Component

    module ClassMethods
      
      def url_param_evaluators
        @url_param_evaluators ||= {}
      end
      
      attr_accessor :evaluated_url_params
      
      def router_param(name, &block)
        
        url_param_evaluators[name] = block
        
        class << self
          
          define_method name do
            evaluated_url_params[name]
          end
        end
        
        define_method name do
          self.class.send(name)
        end
        
      end
      
    end

    def route_handler(*args)
      Router::RR::RouteHandler(*args)
    end

    def link(opts = {}, &block)
      opts[:params] = opts[:params].to_n if opts[:params]
      Router::RR::Link(opts, &block)
    end
    
  end
end
