module Hyperloop
  module Resource
    class SecurityError < StandardError
    end

    module SecurityGuards
      def self.included(base)
        base.extend(Hyperloop::Resource::SecurityGuards::ClassMethods)
      end

      module ClassMethods
        def valid_record_class_params
          @valid_record_class_params = Hyperloop.valid_record_class_params.freeze
        end

        def valid_record_id_params
          @valid_record_id_params ||= Hyperloop.valid_record_class_params.map { |m| m + '_id' }.freeze
        end
      end

      def guarded_record_from_params(params)
        self.class.valid_record_id_params.each do |record_id|
          if params.has_key?(record_id)
            record_class = record_id[0..-3].camelize.constantize
            return [record_class.find(params[record_id]),  params[record_id]]
          end
        end
        raise Hyperloop::Resource::SecurityError
      end

      def guarded_record_class(model_name)
        raise Hyperloop::Resource::SecurityError unless self.class.valid_record_class_params.include?(model_name) # guard
        model_name.camelize.constantize
      end
    end
  end
end
