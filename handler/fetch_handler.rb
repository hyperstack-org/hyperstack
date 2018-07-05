module Hyperloop
  module Resource
    class FetchHandler
      include Hyperloop::Resource::SecurityGuards

      def process_request(request)
        result = {}

        request.each_key do |model_name|
          model = guarded_record_class(model_name)
          result[model_name] = { instances: {}}

          fetch_instances_and_process(request[model_name][:instances], result[model_name][:instances], model) if request[model_name].has_key?(:instances)
          fetch_scopes(request[model_name], result[model_name], model) if request[model_name].has_key?(:methods)
          execute_class_methods(request[model_name], result[model_name], model) if request[model_name].has_key?(:methods)
        end

        result
      end

      private

      def execute_class_methods(request_model, result_model, model)
        request_model[:methods].each_key do |method_name|

          # security guard
          sym_method_name = method_name.to_sym
          result_model.merge!(methods: { method_name => model.send(sym_method_name) }) if model.rest_class_methods.has_key?(sym_method_name)
        end
      end

      def execute_instance_methods(request_instance, result_instance, model, record)
        request_instance[:methods].each_key do |method_name|

          # security guard
          sym_method_name = method_name.to_sym
          result_instance.merge!(methods: { method_name => record.send(sym_method_name) }) if model.rest_methods.has_key?(sym_method_name)
        end
      end

      def fetch_instances_and_process(request_instances, result_instances, model)
        request_instances.each_key do |record_id|

          record = model.find(record_id)
          result_instances[record_id] = { properties: record.to_hash }

          fetch_relations(request_instances[record_id], result_instances[record_id], model, record) if request_instances[record_id].has_key?(:relations)
          execute_instance_methods(request_instances[record_id], result_instances[record_id], model, record) if request_instances[record_id].has_key?(:methods)
        end
      end

      def fetch_relations(request_instance, result_instance, model, record)
        request_instance[:relations].each_key do |relation_name|

          # security guard
          sym_relation_name = relation_name.to_sym
          has_relation = model.reflections.has_key?(sym_relation_name) # for neo4j, key is a symbol
          has_relation = model.reflections.has_key?(relation_name) unless has_relation

          result_instance.merge!(relations: { relation_name => record.send(sym_relation_name)}) if  has_relation
        end
      end

      def fetch_scopes(request_model, result_model, model)
        request_model[:scopes].each_key do |scope_name|

          # security guard
          sym_scope_name = scope_name.to_sym
          args = request_model[:scopes][scope_name]
          result_model.merge!(scopes: { scope_name => model.send(sym_scope_name, *args) }) if model.resource_scopes.include?(scope_name)
        end
      end
    end
  end
end