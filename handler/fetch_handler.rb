class FetchHandler
  include Hyperstack::Resource::SecurityGuards

  def process_request(request)
    result = {}

    request.keys.each do |model_name|
      # begin
        model = guarded_record_class(model_name)

        result[model_name] = {}
        request[model_name].keys.each do |fetchables|
          method_name = "process_model_#{fetchables}".to_sym
          if respond_to?(method_name, true)
            send(method_name, request[model_name], result[model_name], model)
          else
            result.merge!(model_name => { errors: { fetchables => 'No such thing to fetch!' }})
          end
        end
      # rescue
      #  result.merge!(errors: { model_name => 'No such model or access forbidden!' })
      # end
    end

    result
  end

  private

  def process_instance_methods(request_instance, result_instance, model, record)
    request_instance['methods'].keys.each do |method_name|
      sym_method_name = method_name.to_sym
      if model.rest_methods.has_key?(sym_method_name) # security guard
        request_instance['methods'][method_name].keys.each do |args|
          result_instance.merge!(methods: { method_name => { args => record.send(sym_method_name, *args) }})
        end
      else
        result_instance.merge!(errors: { method_name => 'No such method!'})
      end
    end
  end

  def process_instance_relations(request_instance, result_instance, _model, record)
    request_instance['relations'].keys.each do |relation_name|
      sym_relation_name = relation_name.to_sym
      relation_type = record.class.reflect_on_association(sym_relation_name)&.macro
      if relation_type # security guard
        relation_result = record.send(sym_relation_name)
        relation_hash = {}
        if %i[has_many has_and_belongs_to_many].include?(relation_type)
          relation_result.each do |relation_record|
            relation_record_model = relation_record.class.to_s.underscore
            relation_hash[relation_record_model] = {} unless relation_hash.has_key?(relation_record_model)
            record_json = relation_record.as_json
            if record_json.has_key?(relation_record_model)
              # for neo4j
              relation_hash[relation_record_model].merge!(relation_record.id => { properties: record_json[relation_record_model] })
            else
              # for active_record
              relation_hash[relation_record_model].merge!(relation_record.id => { properties: record_json })
            end
          end
        else
          # its a belongs_to or has_one, relation_result is the record or nil
          if relation_result.nil?
            relation_hash.merge!({})
          else
            relation_hash.merge!(relation_result.class.to_s.underscore => { relation_result.id => { properties: relation_result.as_json }})
          end
        end
        result_instance.merge!(relations: { relation_name => relation_hash })
      else
        result_instance.merge!(errors: { relation_name => 'No such relation!'})
      end
    end
  end

  def process_model_instances(request_model, result_model, model)
    result_model[:instances] = {} unless result_model.has_key?(:instances)
    result_instances = result_model[:instances]
    request_model['instances'].keys.each do |record_id|
      record = begin
                 model.find(record_id)
               rescue ActiveRecord::RecordNotFound
                 nil
               end
      if record
        result_instances[record_id] = { properties: record.as_json }
        request_model['instances'][record_id].keys.each do |fetchables|
          method_name = "process_instance_#{fetchables}".to_sym
          if respond_to?(method_name, true)
            send(method_name, request_model['instances'][record_id], result_instances[record_id], model, record)
          else
            result_instances[record_id].merge!(errors: { fetchables => 'No such thing to fetch' })
          end
        end
      else
        result_instances[record_id] = { errors: 'Record not found!' }
      end
    end
  end

  def process_model_methods(request_model, result_model, model)
    request_model['methods'].keys.each do |method_name|
      sym_method_name = method_name.to_sym
      if model.rest_class_methods.has_key?(sym_method_name) # security guard
        result_model.merge!(methods: { method_name => model.send(sym_method_name) })
      else
        result_model.merge!(errors: { method_name => 'No such method!'})
      end
    end
  end

  def process_model_scopes(request_model, result_model, model)
    request_model['scopes'].keys.each do |scope_name|
      sym_scope_name = scope_name.to_sym
      args_json = request_model['scopes'][scope_name]
      if scope_name == 'all' || model.resource_scopes.include?(sym_scope_name) # security guard
        args = Oj.load(args_json.keys.first)
        scope_result = if args == []
                         model.send(sym_scope_name)
                       else
                         model.send(sym_scope_name, *args)
                       end
        scopes_hash = {}
        scope_result.each do |scope_record|
          scope_record_model = scope_record.class.to_s.underscore
          scopes_hash[scope_record_model] = {} unless scopes_hash.has_key?(scope_record_model)
          record_json = scope_record.as_json
          if record_json.has_key?(scope_record_model)
            # for neo4j
            scopes_hash[scope_record_model].merge!(scope_record.id => { properties: record_json[scope_record_model] })
          else
            # for active_record
            scopes_hash[scope_record_model].merge!(scope_record.id => { properties: record_json })
          end
        end
        result_model.merge!(scopes: { scope_name => { args => scopes_hash }})
      else
        result_model.merge!(errors: { scope_name => 'No such scope!'})
      end
    end
  end
end
