module ActiveRecord
  # ActiveRecord monkey patches
  # 1 - Setup synchronization after commits
  # 2 - Update scope to accept different procs for server and client
  class Base
    class << self

      def _synchromesh_scope_args_check(args)
        opts = if args.count == 2 && args[1].is_a?(Hash)
                 args[1].merge(server: args[0])
               elsif args[0].is_a? Hash
                 args[0]
               else
                 { server: args[0] }
               end
        return opts if opts.is_a?(Hash) && opts[:server].respond_to?(:call)
        raise 'must provide either a proc as the first arg or by the '\
              '`:server` option to scope and default_scope methods'
      end

      alias pre_synchromesh_scope scope
      alias pre_synchromesh_default_scope default_scope

      if RUBY_ENGINE != 'opal'

        def scope(name, *args, &block)
          opts = _synchromesh_scope_args_check(args)
          pre_synchromesh_scope(name, opts[:server], &block)
        end

        def default_scope(*args, &block)
          opts = _synchromesh_scope_args_check(args)
          pre_synchromesh_default_scope(opts[:server], &block)
        end

      else

        alias pre_synchromesh_method_missing method_missing

        def method_missing(name, *args, &block)
          if [].respond_to?(name)
            all.send(name, *args, &block)
          else
            pre_synchromesh_method_missing(name, *args, &block)
          end
        end

        def create(*args, &block)
          new(*args).save(&block)
        end

        def _synchromesh_scope_descriptions
          @scope_descriptions ||= {}
        end

        def scope(name, *args)
          opts = _synchromesh_scope_args_check(args)
          scope_description = ReactiveRecord::ScopeDescription.new(self, name, opts)
          singleton_class.send(:define_method, name) do |*args|
            # args = args.count.zero? ? name : [name, *args]
            all.apply_scope2(scope_description, *name, *args)
          end
          singleton_class.send(:define_method, "#{name}=") do |collection|
            all.replace_scope(name, collection)
          end
        end

        def default_scope(*args)
          opts = _synchromesh_scope_args_check(args)
          all.apply_scope2(ReactiveRecord::ScopeDescription.new(self, :all, opts))
        end

        def all
          @_default_scope ||=
            ReactiveRecord::Collection
            .new(self, nil, nil, self, 'all')
            .extend(ReactiveRecord::UnscopedCollection)
        end

        def unscoped
          @_unscoped ||=
            ReactiveRecord::Collection
            .new(self, nil, nil, self, 'unscoped')
            .extend(ReactiveRecord::UnscopedCollection)
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
                  if value
                    [assoc.attribute, {id: [value], type: [nil]}]
                  else
                    [assoc.attribute, [nil]]
                  end
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

    if RUBY_ENGINE != 'opal'

      after_commit :synchromesh_after_change, on: [:create, :update]
      after_commit :synchromesh_after_destroy, on: [:destroy]

      def synchromesh_after_change
        return if previous_changes.empty?
        Synchromesh.after_change self
      end

      def synchromesh_after_destroy
        Synchromesh.after_destroy self
      end

    else

      def update_attribute(attr, value, &block)
        send("#{attr}=", value)
        save(validate: false, &block)
      end

      def update(attrs = {}, &block)
        attrs.each { |attr, value| send("#{attr}=", value) }
        save(&block)
      end

      def <=>(other)
        id.to_i <=> other.id.to_i
      end
    end
  end
end
