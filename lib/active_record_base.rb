module ReactiveRecord
  class PsuedoRelationArray < Array
    # allows us to easily handle scopes and finder_methods which return arrays of items (instead of ActiveRecord::Relations - see below)
    attr_accessor :__synchromesh_permission_granted
    attr_accessor :acting_user
    def __secure_collection_check(acting_user)
      self
    end
  end
end

module ActiveRecord
  class Relation
    attr_accessor :__synchromesh_permission_granted
    attr_accessor :acting_user
    def __secure_collection_check(acting_user)
      return self if __synchromesh_permission_granted
      return self if __secure_remote_access_to_unscoped(acting_user).__synchromesh_permission_granted
      denied!
    end
  end

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

      def do_not_synchronize
        @do_not_synchronize = true
      end

      def do_not_synchronize?
        @do_not_synchronize
      end

      if RUBY_ENGINE != 'opal'

        def __secure_remote_access_to_all(acting_user)
          all
        end

        def __secure_remote_access_to_unscoped(acting_user)
          unscoped
        end

        def denied!
          Hyperloop::InternalPolicy.raise_operation_access_violation
        end

        alias pre_synchromesh_default_scope default_scope

        def scope(name, *args, &block)
          __synchromesh_regulate_from_macro(
            (opts = _synchromesh_scope_args_check(args)),
            name,
            respond_to?(:"__secure_remote_access_to_#{name}"),
            &method(:regulate_scope)
          )
          pre_synchromesh_scope(name, opts[:server], &block)
        end

        def __set_synchromesh_permission_granted(r, obj, acting_user, args = [], &block)
          r.__synchromesh_permission_granted = try(:__synchromesh_permission_granted) || !block
          unless r.__synchromesh_permission_granted
            old = acting_user
            obj.acting_user = acting_user
            r.__synchromesh_permission_granted = obj.instance_exec(*args, &block)
          end
          r
        ensure
          obj.acting_user = old
        end

        def regulate_scope(name, &block)
          name, block = __synchromesh_parse_regulator_params(name, block)
          singleton_class.send(:define_method, :"__secure_remote_access_to_#{name}") do |acting_user, *args|
            r = send(name, *args)
            r = ReactiveRecord::PsuedoRelationArray.new(r) if r.is_a? Array
            __set_synchromesh_permission_granted(r, r, acting_user, args, &block)
          end
        end

        def regulate_default_scope(&block)
          regulate_scope(:all, &block)
        end

        def finder_method(name, &block)
          singleton_class.send(:define_method, :"__secure_remote_access_to__#{name}") do |acting_user, *args|
            this = self.respond_to?(:acting_user) ? self : all
            begin
              old = this.acting_user
              this.acting_user = acting_user
              ReactiveRecord::PsuedoRelationArray.new([this.instance_exec(*args, &block)])
            ensure
              this.acting_user = old
            end
          end
          singleton_class.send(:define_method, name) do |*args|
            all.instance_exec(*args, &block)
          end
        end

        def __synchromesh_parse_regulator_params(name, block)
          if name.is_a? Hash
            name, block = name.first
            if %i[denied! deny denied].include? block
              block = ->(*_args) { denied! }
            elsif !block.is_a? Proc
              value = block
              block = ->(*_args) { value }
            end
          end
          [name, block || ->(*_args) { true }]
        end

        def regulate_relationship(name, &block)
          name, block = __synchromesh_parse_regulator_params(name, block)
          define_method(:"__secure_remote_access_to_#{name}") do |acting_user, *args|
            self.class.__set_synchromesh_permission_granted(send(name, *args), self, acting_user, &block)
          end
        end

        def __synchromesh_regulate_from_macro(opts, name, already_defined)
          if opts.key?(:regulate)
            yield name => opts[:regulate]
          elsif !already_defined
            yield name => ->(*_args) {}
          end
        end

        def default_scope(*args, &block)
          __synchromesh_regulate_from_macro(
            (opts = _synchromesh_scope_args_check([*block, *args])),
            :all,
            respond_to?(:__secure_remote_access_to_all),
            &method(:regulate_scope)
          )
          pre_synchromesh_default_scope(opts[:server], &block)
        end

        def server_method(name, opts = {}, &block)
          # callable from the server internally
          define_method(name, &block)
          # callable remotely from the client
          define_method("__secure_remote_access_to_#{name}") do |acting_user, *args|
            begin
              old = self.acting_user
              self.acting_user = acting_user
              send(name, *args)
            ensure
              self.acting_user = old
            end
          end
        end

        def __secure_remote_access_to_find(acting_user, *args)
          find(*args)
        end

        def __secure_remote_access_to_find_by(acting_user, *args)
          find_by(*args)
        end

        def __secure_remote_access_to_unscoped(acting_user, *args)
          unscoped(*args)
        end

        alias pre_syncromesh_has_many has_many

        def has_many(name, *args, &block)
          __synchromesh_regulate_from_macro(
            opts = args.extract_options!,
            name,
            method_defined?(:"__secure_remote_access_to_#{name}"),
            &method(:regulate_relationship)
          )
          pre_syncromesh_has_many name, *args, opts.except(:regulate), &block
        end

        [:belongs_to, :has_one].each do |macro|
          alias_method :"pre_syncromesh_#{macro}", macro
          define_method(macro) do |name, scope = nil, opts = {}, &block|
            define_method(:"__secure_remote_access_to_#{name}") do |_acting_user, *args, &block|
              send(name, *args, &block)
            end
            send(:"pre_syncromesh_#{macro}", name, scope, opts, &block)
          end
        end

      else

        alias pre_synchromesh_method_missing method_missing

        def method_missing(name, *args, &block)
          return all.send(name, *args, &block) if [].respond_to?(name)
          if name.end_with?('!')
            return send(name.chop, *args, &block).send(:reload_from_db) rescue nil
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
          # singleton_class.send(:define_method, "#{name}=") do |_collection|
          #   raise 'NO LONGER IMPLEMENTED - DOESNT PLAY WELL WITH SYNCHROMESH'
          # end
        end

        def default_scope(*args, &block)
          opts = _synchromesh_scope_args_check([*block, *args])
          @_default_scopes ||= []
          @_default_scopes << opts
        end

        def all
          ReactiveRecord::Base.default_scope[self] ||=
            begin
            root = ReactiveRecord::Collection
                   .new(self, nil, nil, self, 'all')
                   .extend(ReactiveRecord::UnscopedCollection)
            (@_default_scopes || [{ client: -> () { true } }]).inject(root) do |scope, opts|
              scope.build_child_scope(ReactiveRecord::ScopeDescription.new(self, :all, opts))
            end
          end
        end

        # def all=(_collection)
        #   raise "NO LONGER IMPLEMENTED DOESNT PLAY WELL WITH SYNCHROMESH"
        # end

        def unscoped
          ReactiveRecord::Base.unscoped[self] ||=
            ReactiveRecord::Collection
            .new(self, nil, nil, self, 'unscoped')
            .extend(ReactiveRecord::UnscopedCollection)
        end

        def finder_method(name)
          ReactiveRecord::ScopeDescription.new(self, "_#{name}", {})
          [name, "#{name}!"].each do |method|
            singleton_class.send(:define_method, method) do |*vargs|
              all.apply_scope("_#{method}", *vargs).first
            end
          end
        end
      end
    end

    if RUBY_ENGINE != 'opal'

      def denied!
        Hyperloop::InternalPolicy.raise_operation_access_violation
      end

      def do_not_synchronize?
        self.class.do_not_synchronize?
      end

      after_commit :synchromesh_after_create,  on: [:create]
      after_commit :synchromesh_after_change,  on: [:update]
      after_commit :synchromesh_after_destroy, on: [:destroy]

      def synchromesh_after_create
        return if do_not_synchronize?
        ReactiveRecord::Broadcast.after_commit :create, self
      end

      def synchromesh_after_change
        return if do_not_synchronize? || previous_changes.empty?
        ReactiveRecord::Broadcast.after_commit :change, self
      end

      def synchromesh_after_destroy
        return if do_not_synchronize?
        ReactiveRecord::Broadcast.after_commit :destroy, self
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
