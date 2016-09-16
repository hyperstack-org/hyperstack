module ActiveRecord
  # ActiveRecord monkey patches
  # 1 - Setup synchronization after commits
  # 2 - Update scope to accept different procs for server and client
  class Base
    if RUBY_ENGINE != 'opal'
      after_commit :synchromesh_after_change, on: [:create, :update]
      after_commit :synchromesh_after_destroy, on: [:destroy]

      def synchromesh_after_change
        Synchromesh.after_change self unless previous_changes.empty?
      end

      def synchromesh_after_destroy
        Synchromesh.after_destroy self
      end
    end

    class << self

      alias old_scope scope

      if RUBY_ENGINE != 'opal'

        def scope(name, server_side_arg, joins_list = [], &block)
          server_side_arg = joins_list unless server_side_arg.respond_to? :call
          old_scope(name, server_side_arg)
        end

      else

        def reactive_record_scopes
          @rr_scopes ||= {}
        end

        def scope(name, server_side_arg, joins_list = nil, &block)
          ReactiveRecord::Collection.add_scope(self, name, server_side_arg, joins_list, &block)
          singleton_class.send(:define_method, name) do | *args |
            args = (args.count == 0) ? name : [name, *args]
            ReactiveRecord::Base.class_scopes(self)[args] ||=
              ReactiveRecord::Collection.new(self, nil, nil, self, args).set_scope(name)
          end
          singleton_class.send(:define_method, "#{name}=") do |collection|
            ReactiveRecord::Base.class_scopes(self)[name] = collection
          end
        end

        def _react_param_conversion(param, opt = nil)
          param = Native(param)
          param = JSON.from_object(param.to_n) if param.is_a? Native::Object
          result = if param.is_a? self
            param
          elsif param.is_a? Hash
            if opt == :validate_only
              klass = ReactiveRecord::Base.infer_type_from_hash(self, param)
              klass == self or klass < self
            else
              if param[primary_key]
                target = find(param[primary_key])
              else
                target = new
              end
              associations = reflect_on_all_associations
              param = param.collect do |key, value|
                assoc = reflect_on_all_associations.detect do |assoc|
                  assoc.association_foreign_key == key
                end
                if assoc
                  [assoc.attribute, {id: [value], type: [nil]}]
                else
                  [key, [value]]
                end
              end
              ReactiveRecord::ServerDataCache.load_from_json(Hash[param], target)
              target
            end
          else
            nil
          end
          result
        end
      end

    end
  end
end
