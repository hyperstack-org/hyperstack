module ActiveRecord
  # ActiveRecord monkey patches
  # 1 - Setup synchronization after commits
  # 2 - Update scope to accept different procs for server and client
  class Base
    if RUBY_ENGINE != 'opal'
      after_commit :synchromesh_after_change, on: [:create, :update]
      after_commit :synchromesh_after_destroy, on: [:destroy]

      def synchromesh_after_change
        Synchromesh.after_change self
      end

      def synchromesh_after_destroy
        Synchromesh.after_destroy self
      end
    end

    class << self
      def no_client_sync
        @no_client_sync = true
      end

      alias old_scope scope

      def scope(name, server_proc, client_proc = nil)
        if !server_proc.respond_to?(:call)
          server_proc = client_proc
        elsif client_proc.nil?
          add_client_scope(name, server_proc) unless @no_client_sync
        elsif client_proc.respond_to?(:call)
          add_client_scope(name, client_proc)
        end
        old_scope(name, server_proc)
      end

      def add_client_scope(name, client)
        to_sync name do |scope, model|
          if ReactiveRecord::SyncWrapper.new(model).instance_eval(&client)
            scope << model
          else
            scope.delete(model)
          end
        end if RUBY_ENGINE == 'opal'
      end
    end
  end
end
