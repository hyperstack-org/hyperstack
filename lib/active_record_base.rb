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
      end

    end
  end
end
