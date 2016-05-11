module ActiveRecord
  class Base

    puts "&&&&&&&&&&&&&&&&&&&& updating active record base &&&&&&&&&&&&&&&&&&&&&&&&"

    class << self

      def no_auto_sync
        @no_auto_sync = true
      end

      alias_method :old_scope, :scope

      def scope(name, server, client = nil)
        puts "********************AR BASE NOW scoping #{name} with #{server}"
        if server == :no_sync
          server = client
          client = nil
        elsif client.nil? && @no_auto_sync.nil?
          client = server
        end
        if RUBY_ENGINE == 'opal' && client
          to_sync name do |scope, model|
            puts "to_sync #{name}"
            if ReactiveRecord::SyncWrapper.new(model).instance_eval(&client)
              scope << model
            else
              scope.delete(model)
            end
          end
        end
        old_scope(name, server)
      end
    end

    if RUBY_ENGINE != 'opal'

      after_commit :syncromesh_after_change, on: [:create, :update]
      after_commit :syncromesh_after_destroy, on: [:destroy]

      def syncromesh_after_change
        puts "**********************after_change callback"
        Syncromesh.after_change self
      end

      def syncromesh_after_destroy
        puts "***********************after_destroy callback"
        Syncromesh.after_destroy self
      end

    end

  end
end
