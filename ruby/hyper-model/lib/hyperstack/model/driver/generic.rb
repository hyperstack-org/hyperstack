module Hyperstack
  module Model
    module Driver
      class Generic
        def initialize(model)
          @model = model
        end

        if RUBY_ENGINE != 'opal'
          def class_remote_method(sym_method_name, *args)
            @model.send(sym_method_name, *args)
          end
          def collection_query(record, sym_query_name)
            record.send(sym_query_name)
          end

          def create(data_hash)
            @model.create(data_hash)
          end

          def destroy(record)
            record.destroy
          end

          def find(id)
            @model.find(id)
          end

          def find_by(sym_find_by_method, *args)
            @model.send(sym_find_by_method, *args)
          end

          def has_relation?(sym_relation_name)
            false
          end

          def link(left_record, right_record, sym_relation_name = nil)
            left_record.send(sym_relation_name) << right_record
          end

          def relation(record, sym_relation_name)
            record.send(sym_relation_name)
          end

          def remote_method(record, sym_method_name, *args)
            record.send(sym_method_name, *args)
          end

          def scope(sym_scope_name, *args)
            @model.send(sym_scope_name, *args)
          end

          def touch(record)
            record.touch
          end

          def unlink(left_record, right_record, sym_relation_name = nil)
            record.send(sym_relation_name).delete(right_record)
          end

          def update(record, data_hash)
            record.update(data_hash)
          end

          def where(hash_arg)
            @model.where(hash_arg)
          end
        end
      end
    end
  end
end