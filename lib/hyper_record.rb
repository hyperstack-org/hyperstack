if RUBY_ENGINE == 'opal'
  require 'hyper_record/dummy_value'
  require 'hyper_record/collection'
  require 'hyper_record/transducer'
  require 'hyper_record/class_methods'
  require 'hyper_record/client_instance_methods'

  module HyperRecord
    # get global api_path
    #
    # @return [String]
    def self.api_path
      @api_path ||= Hyperloop.api_path
    end

    # set global api path
    #
    # @return [String]
    def self.api_path=(api_path)
      @api_path = api_path
    end

    # get global transport
    #
    # @return [Class]
    def self.transport
      @transport ||= Hyperloop::Transport::HTTP
    end

    # set global transport
    #
    # @return [Class]
    def self.transport=(transport)
      @transport = transport
    end

    # get global request transducer
    #
    # @return [HyperRecord::Transducer]
    def self.request_transducer
      @transducer ||= HyperRecord::Transducer
    end

    # set global request transducer
    #
    # @return [HyperRecord::Transducer]
    def self.request_transducer=(transducer)
      @transducer = transducer
    end

    # get response processor
    #
    # @return [Class]
    def self.response_processor
      @response_processor ||= Hyperloop::Resource::ResponseProcessor
    end

    # set response_processor
    #
    # @return [Class]
    def self.response_processor=(processor)
      @response_processor = processor
    end

    def self.included(base)
      base.extend(HyperRecord::ClassMethods)
      base.include(HyperRecord::ClientInstanceMethods)
      base.class_eval do
        scope :all
      end
    end
  end
else
  require 'hyper_record/server_class_methods'
  require 'hyper_record/pub_sub'
end


