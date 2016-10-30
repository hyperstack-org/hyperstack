module ReactiveRecord
  # patches and new methods
  class Base

    class << self
      attr_reader :outer_scopes

      def default_scope
        @class_scopes[:default_scope]
      end

      def unscoped
        @class_scopes[:unscoped]
      end

      def add_to_outer_scopes(item)
        @outer_scopes << item
      end
    end

    # when_not_saving will wait until reactive-record is not saving a model.
    # Currently there is no easy way to do this without polling.
    def self.when_not_saving(model)
      if @records[model].detect(&:saving?)
        poller = every(0.1) do
          unless @records[model].detect(&:saving?)
            poller.stop
            yield model
          end
        end
      else
        yield model
      end
    end

    # While evaluating scopes we want to catch any requests
    # to the server.  Once we catch any requests to the server
    # then all the further scopes in that chain will be made
    # at the server.

    class << self
      class DbRequestMade < RuntimeError; end

      def catch_db_requests(return_val = nil)
        @catch_db_requests = true
        yield
      rescue DbRequestMade => e
        puts "Warning request for server side data during scope evaluation: #{e.message}"
        return_val
      ensure
        @catch_db_requests = false
      end

      alias pre_synchromesh_load_from_db load_from_db

      def load_from_db(*args)
        raise DbRequestMade, args if @catch_db_requests
        pre_synchromesh_load_from_db(*args)
      end
    end

    # once this method is integrated back into reactive-record, remove the duplicate
    # code from within the destroy method (in file isomorphic_base)
    def destroy_associations
      model.reflect_on_all_associations.each do |association|
        if association.collection?
          attributes[association.attribute].replace([]) if attributes[association.attribute]
        else
          @ar_instance.send("#{association.attribute}=", nil)
        end
      end
    end
  end
end
