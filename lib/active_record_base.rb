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

      def do_not_synchronize
        @do_not_synchronize = true
      end

      def do_not_synchronize?
        @do_not_synchronize
      end

      if RUBY_ENGINE != 'opal'

        def scope(name, *args, &block)
          opts = _synchromesh_scope_args_check(args)
          pre_synchromesh_scope(name, opts[:server], &block)
        end

        def default_scope(*args, &block)
          opts = _synchromesh_scope_args_check([*block, *args])
          pre_synchromesh_default_scope(opts[:server], &block)
        end

      else

        alias pre_synchromesh_method_missing method_missing

        def method_missing(name, *args, &block)
          #return get_by_index(*args).first if name == "[]"
          return all.send(name, *args, &block) if [].respond_to?(name)
          if name =~ /\!$/
            return send(name.gsub(/\!$/,''), *args, &block).send(:reload_from_db) rescue nil
          end
          pre_synchromesh_method_missing(name, *args, &block)
        end

        def create(*args, &block)
          new(*args).save(&block)
        end

        def scope(name, *args)
          opts = _synchromesh_scope_args_check(args)
          scope_description = ReactiveRecord::ScopeDescription.new(self, name, opts)
          singleton_class.send(:define_method, name) do |*vargs|
            all.build_child_scope(scope_description, *name, *vargs)
          end
          singleton_class.send(:define_method, "#{name}=") do |_collection|
            raise 'NO LONGER IMPLEMENTED - DOESNT PLAY WELL WITH SYNCHROMESH'
            # all.replace_child_scope(name, collection)
          end
        end

        def default_scope(*args, &block)
          opts = _synchromesh_scope_args_check([*block, *args])
          @_default_scopes ||= []
          @_default_scopes << opts
        end

        def all
          ReactiveRecord::Base.default_scope[self] ||=
            if @_default_scopes
              root = ReactiveRecord::Collection
                     .new(self, nil, nil, self, 'all')
                     .extend(ReactiveRecord::UnscopedCollection)
              @_default_scopes.inject(root) do |scope, opts|
                scope.build_child_scope(ReactiveRecord::ScopeDescription.new(self, :all, opts))
              end
            end || unscoped
        end

        def all=(_collection)
          raise "NO LONGER IMPLEMENTED DOESNT PLAY WELL WITH SYNCHROMESH"
        end

        def unscoped
          ReactiveRecord::Base.unscoped[self] ||=
            ReactiveRecord::Collection
            .new(self, nil, nil, self, 'unscoped')
            .extend(ReactiveRecord::UnscopedCollection)
        end
      end
    end

    if RUBY_ENGINE != 'opal'

      def do_not_synchronize?
        self.class.do_not_synchronize?
      end

      after_commit :synchromesh_after_create,  on: [:create]
      after_commit :synchromesh_after_change,  on: [:update]
      after_commit :synchromesh_after_destroy, on: [:destroy]

      def synchromesh_after_create
        return if do_not_synchronize? || previous_changes.empty?
        HyperMesh.after_commit :create, self
      end

      def synchromesh_after_change
        return if do_not_synchronize? || previous_changes.empty?
        HyperMesh.after_commit :change, self
      end

      def synchromesh_after_destroy
        return if do_not_synchronize?
        HyperMesh.after_commit :destroy, self
      end
    else

      scope :limit, ->() {}
      scope :offset, ->() {}

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

  InternalMetadata.do_not_synchronize if defined? InternalMetadata

end
