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

      alias pre_synchromesh_scope scope

      if RUBY_ENGINE != 'opal'

        def scope(name, body, opts = {}, &block)
          pre_synchromesh_scope(name, body, &block)
        end

      else

        def unscoped
          ReactiveRecord::Base.class_scopes(self)[:unscoped] ||= ReactiveRecord::Collection.new(self, nil, nil, self, "unscoped")
        end

        alias pre_synchromesh_method_missing method_missing

        def method_missing(name, *args, &block)
          if [].respond_to?(name)
            all.send(name, *args, &block)
          else
            pre_synchromesh_method_missing(name, *args, &block)
          end
        end

        def reactive_record_scopes
          @rr_scopes ||= {}
        end

        def scope(name, body, opts = {}, &block)
          ReactiveRecord::Collection.add_scope(self, name, opts)
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
