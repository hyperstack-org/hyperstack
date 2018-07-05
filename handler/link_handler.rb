module Hyperloop
  module Resource
    class LinkHandler

      SINGLE_RELATIONS = %i[belongs_to has_one]

      def process_request(request)
        result = {}

        request.each_key do |model_name|

          # security guard
          model = guarded_record_class(model_name)
          request[model_name]['instances'].each_key do |id|
            record = model.find(id)

            updated = false

            request[model_name]['instances'][id]['relations'].each_key do |relation_name|
              # security guard
              sym_relation_name = relation_name.to_sym
              has_relation = model.reflections.has_key?(sym_relation_name) # for neo4j, key is a symbol
              has_relation = model.reflections.has_key?(relation_name) unless has_relation

              if has_relation

                request[model_name]['instances'][id]['relations'][relation_name].each_key do |right_model_name|
                  # security guard
                  right_model = guarded_record_class(right_model_name)

                  request[model_name]['instances'][id]['relations'][relation_name][right_model_name].each_key do |right_id|
                    right_record = right_model.find(right_id)

                    if right_record
                      relation_type = model.reflections[sym_relation_name].association.type
                      relation_type = model.reflections[relation_name].association.type unless relation_type
                      if SINGLE_RELATIONS.include?(relation_type)
                        record.send("#{relation_name}=", right_record)
                      else
                        record.send(relation_name) << right_record
                      end
                      updated = true
                      right_record.touch
                    end

                  end
                end
              end
            end

            record.touch if updated
          end
        end

        result
      end
    end
  end
end