module Hyperstack
  module Resource
    class SecurityError < StandardError
    end

    module SecurityGuards
      def self.included(base)
        base.extend(Hyperstack::Resource::SecurityGuards::ClassMethods)
      end

      module ClassMethods
        def valid_record_class_params
          @valid_record_class_params = Hyperstack.valid_record_class_params.freeze
        end

        def valid_record_id_params
          @valid_record_id_params ||= Hyperstack.valid_record_class_params.map { |m| m + '_id' }.freeze
        end
      end

      def guarded_record_from_params(params)
        self.class.valid_record_id_params.each do |record_id|
          if params.has_key?(record_id)
            record_class = record_id[0..-3].camelize.constantize
            return [record_class.find(params[record_id]),  params[record_id]]
          end
        end
        raise Hyperstack::Resource::SecurityError
      end

      def guarded_record_class(model_name)
        raise Hyperstack::Resource::SecurityError unless self.class.valid_record_class_params.include?(model_name) # guard
        model_name.camelize.constantize
      end
    end
  end
end
