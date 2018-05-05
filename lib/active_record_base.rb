# Monkey patches to ActiveRecord for scoping, security, and to synchronize models
module ActiveRecord
  # hyperloop adds new features to scopes to allow for computing scopes on client side
  # and for hinting at what joins are involved in a scope.  _synchromesh_scope_args_check
  # processes these arguments, and the will always leave the true server side scoping
  # proc in the `:server` opts.   This method is common to client and server.
  class Base
    def self._synchromesh_scope_args_check(args)
      opts = if args.count == 2 && args[1].is_a?(Hash)
               args[1].merge(server: args[0])
             elsif args[0].is_a? Hash
               args[0]
             else
               { server: args[0] }
             end
      return opts if opts && opts[:server].respond_to?(:call)
      raise 'must provide either a proc as the first arg or by the '\
            '`:server` option to scope and default_scope methods'
    end
  end
  if RUBY_ENGINE != 'opal'
    # __synchromesh_permission_granted indicates if permission has been given to return a scope
    # The acting_user attribute is set to the current acting_user so regulation methods can check it
    # The __secure_collection_check method is called at the end of a scope chain and will fail if
    # no scope in the chain has positively granted access.

    # allows us to easily handle scopes and finder_methods which return arrays of items
    # (instead of ActiveRecord::Relations - see below)
    class ReactiveRecordPsuedoRelationArray < Array
      attr_accessor :__synchromesh_permission_granted
      attr_accessor :acting_user
      def __secure_collection_check(_acting_user)
        self
      end
    end

    # add the __synchromesh_permission_granted, acting_user and __secure_collection_check
    # methods to Relation
    class Relation
      attr_accessor :__synchromesh_permission_granted
      attr_accessor :acting_user
      def __secure_collection_check(acting_user)
        return self if __synchromesh_permission_granted
        return self if __secure_remote_access_to_unscoped(self, acting_user).__synchromesh_permission_granted
        denied!
      end
    end
    # Monkey patches and extensions to base
    class Base
      class << self
        # every method call that is legal from the client has a wrapper method prefixed with
        # __secure_remote_access_to_

        # The wrapper method may simply return the normal result or may act to secure the data.
        # The simpliest case is for the method to call `denied!` which will raise a Hyperloop
        # access protection fault.

        def denied!
          Hyperloop::InternalPolicy.raise_operation_access_violation
        end

        # Here we set up the base `all` and `unscoped` methods.  See below for more on how
        # access protection works on relationships.

        def __secure_remote_access_to_all(_self, _acting_user)
          all
        end

        def __secure_remote_access_to_unscoped(_self, _acting_user, *args)
          unscoped(*args)
        end

        # finder_method and server_method provide secure RPCs against AR relations and records.
        # The block is called in context with the object, and acting_user is set to the
        # current acting user.  The block may interogate acting_user to insure security as needed.

        # For finder_method we have to preapply `all` so that we always have a relationship

        def finder_method(name, &block)
          singleton_class.send(:define_method, :"__secure_remote_access_to__#{name}") do |this, acting_user, *args|
            this = respond_to?(:acting_user) ? this : all
            begin
              old = this.acting_user
              this.acting_user = acting_user
              # returns a PsuedoRelationArray which will respond to the
              # __secure_collection_check method
              ReactiveRecordPsuedoRelationArray.new([this.instance_exec(*args, &block)])
            ensure
              this.acting_user = old
            end
          end
          singleton_class.send(:define_method, name) do |*args|
            all.instance_exec(*args, &block)
          end
        end

        def server_method(name, _opts = {}, &block)
          # callable from the server internally
          define_method(name, &block)
          # callable remotely from the client
          define_method("__secure_remote_access_to_#{name}") do |_self, acting_user, *args|
            begin
              old = self.acting_user
              self.acting_user = acting_user
              send(name, *args)
            ensure
              self.acting_user = old
            end
          end
        end

        # relationships (and scopes) are regulated using a tri-state system.  Each
        # remote access method will return the relationship as normal but will also set
        # the value of __secure_remote_access_granted using the application defined regulation.
        # Each regulation can explicitly allow the scope to be chained by returning a truthy
        # value from the regulation.  Or each regulation can explicitly deny the scope to
        # be chained by called `denied!`.  Otherwise each regulation can return a falsy
        # value meaning the scope can be changed, but unless some other scope (before or
        # after) in the chain explicitly allows the scope, the entire chain will fail.

        # In otherwords within a chain of relationships and scopes, at least one Regulation
        # must be return a truthy value otherwise the whole chain fails.  Likewise if any
        # regulation called `deined!` the whole chain fails.

        # If no regulation is defined, the regulation is inherited from the superclass, and if
        # no regulation is defined anywhere in the class heirarchy then the regulation will
        # return a falsy value.

        # regulations on scopes are inheritable.  That is if a superclass defines a regulation
        # for a scope, subclasses will inherit the regulation (but can override)

        # helper method to sort out the options on the regulate_scope, regulate_relationship macros.

        # We allow three forms:
        # regulate_xxx name &block  : the block is the regulation
        # regulate_xxx name: const  : const can be denied!, deny, denied, or any other truthy or
        #                             falsy value
        # regulate_xxx name: proc   : the proc is the regulation

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

        # helper method for providing a regulation in line with a scope or relationship
        # this is done using the `regulate` key on the opts.
        # if no regulate key is provided and there is no regulation already defined for
        # this name, then we create one that returns nil (don't care)
        # once we have things figured out, we yield to the provided proc which is either
        # regulate_scope or regulate_relationship

        def __synchromesh_regulate_from_macro(opts, name, already_defined)
          if opts.key?(:regulate)
            yield name => opts[:regulate]
          elsif !already_defined
            yield name => ->(*_args) {}
          end
        end

        # helper method to set the value of __synchromesh_permission_granted on the relationship
        # Set acting_user on the object, then or in the result of running the block in context
        # of the obj with the current value of __synchromesh_permission_granted

        def __set_synchromesh_permission_granted(old_rel, new_rel, obj, acting_user, args = [], &block)
          saved_acting_user = obj.acting_user
          obj.acting_user = acting_user
          new_rel.__synchromesh_permission_granted =
            obj.instance_exec(*args, &block) || (old_rel && old_rel.try(:__synchromesh_permission_granted))
          new_rel
        ensure
          obj.acting_user = saved_acting_user
        end

        # regulate scope has to deal with the special case that the scope returns an
        # an array instead of a relationship.  In this case we wrap the array and go on

        def regulate_scope(name, &block)
          name, block = __synchromesh_parse_regulator_params(name, block)
          singleton_class.send(:define_method, :"__secure_remote_access_to_#{name}") do |this, acting_user, *args|
            r = this.send(name, *args)
            r = ReactiveRecordPsuedoRelationArray.new(r) if r.is_a? Array
            __set_synchromesh_permission_granted(this, r, r, acting_user, args, &block)
          end
        end

        # regulate_default_scope

        def regulate_default_scope(*args, &block)
          block = __synchromesh_parse_regulator_params({ all: args[0] }, block).last unless args.empty?
          regulate_scope(:all, &block)
        end

        # monkey patch scope and default_scope macros to process hyperloop special opts,
        # and add regulations if present

        alias pre_synchromesh_scope scope

        def scope(name, *args, &block)
          __synchromesh_regulate_from_macro(
            (opts = _synchromesh_scope_args_check(args)),
            name,
            respond_to?(:"__secure_remote_access_to_#{name}"),
            &method(:regulate_scope)
          )
          pre_synchromesh_scope(name, opts[:server], &block)
        end

        alias pre_synchromesh_default_scope default_scope

        def default_scope(*args, &block)
          __synchromesh_regulate_from_macro(
            (opts = _synchromesh_scope_args_check([*block, *args])),
            :all,
            respond_to?(:__secure_remote_access_to_all),
            &method(:regulate_scope)
          )
          pre_synchromesh_default_scope(opts[:server], &block)
        end

        # add regulate_relationship method and monkey patch monkey patch has_many macro
        # to add regulations if present

        def regulate_relationship(name, &block)
          name, block = __synchromesh_parse_regulator_params(name, block)
          define_method(:"__secure_remote_access_to_#{name}") do |this, acting_user, *args|
            this.class.__set_synchromesh_permission_granted(
              nil, this.send(name, *args), this, acting_user, &block
            )
          end
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

        # add secure access for find, find_by, and belongs_to and has_one relations.
        # No explicit security checks are needed here, as the data returned by these objects
        # will be further processedand checked before returning.  I.e. it is not possible to
        # simply return `find(1)` but if you try returning `find(1).name` the permission system
        # will check to see if the name attribute can be legally sent to the current acting user.

        def __secure_remote_access_to_find(_self, _acting_user, *args)
          find(*args)
        end

        def __secure_remote_access_to_find_by(_self, _acting_user, *args)
          find_by(*args)
        end

        %i[belongs_to has_one].each do |macro|
          alias_method :"pre_syncromesh_#{macro}", macro
          define_method(macro) do |name, *aargs, &block|
            define_method(:"__secure_remote_access_to_#{name}") do |this, _acting_user, *args|
              this.send(name, *args)
            end
            send(:"pre_syncromesh_#{macro}", name, *aargs, &block)
          end
        end
      end

      def denied!
        Hyperloop::InternalPolicy.raise_operation_access_violation
      end

      # call do_not_synchronize to block synchronization of a model

      def self.do_not_synchronize
        @do_not_synchronize = true
      end

      # used by the broadcast mechanism to determine if this model is to be synchronized

      def self.do_not_synchronize?
        @do_not_synchronize
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

      def __hyperloop_secure_attributes(acting_user)
        accessible_attributes =
          Hyperloop::InternalPolicy.accessible_attributes_for(self, acting_user)
        attributes.select { |attr| accessible_attributes.include? attr.to_sym }
      end

      # regulate built in scopes so they are accesible from the client
      %i[limit offset].each do |scope|
        regulate_scope(scope) {}
      end
    end
  end

  InternalMetadata.do_not_synchronize if defined? InternalMetadata
end
