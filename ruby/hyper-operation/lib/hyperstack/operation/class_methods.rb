module Hyperstack
  class Operation
    module ClassMethods

      SUCCESS_TRACK = 0
      FAIL_TRACK = 1

      def First(description = nil, &block)
        raise "#{self}: First: First already defined, can only be defined once!" if _first_defined?
        raise "#{self}: First: Must be either a block or a symbol or a descriptive string!" if description && block_given?

        if block_given?
          _add_to_pipe(SUCCESS_TRACK, nil, &block)
          _description_pipe << [:first, nil]
        elsif description
          description = description.to_s
          if description.start_with?(':')
            # its actually a symbol, probably, but opal cant differentiate
            _add_to_pipe(SUCCESS_TRACK, description)
          else
            _pipe << Array.new(2)
          end
          _description_pipe << [description, nil]
        end

        @_first_defined = true
      end

      def Then(description = nil, &block)
        raise "#{self}: Then: First must be defined first!" unless _first_defined?
        raise "#{self}: Then: Finally already defined, cannot add additional steps!" if _finally_defined?
        raise "#{self}: Then: Must be either a block or a symbol or a descriptive string!" if description && block_given?

        if block_given?
          pipe_index = _pipe.size
          _add_to_pipe(SUCCESS_TRACK, nil, &block)
          _description_pipe << ["then_#{pipe_index}", nil]
        elsif description
          description = description.to_s
          if description.start_with?(':')
            # its actually a symbol, probably, but opal cant differentiate
            _add_to_pipe(SUCCESS_TRACK, description)
          else
            _pipe << Array.new(2)
          end
          _description_pipe << [description, nil]
        end
      end

      def Finally(description = nil, &block)
        raise "#{self}: Finally: First must be defined first!" unless _first_defined?
        raise "#{self}: Finally: Already defined, can only be defined once!" if _finally_defined?
        raise "#{self}: Finally: Must be either a block or a symbol or a descriptive string!" if description && block_given?

        if block_given?
          _add_to_pipe(SUCCESS_TRACK, nil, &block)
          _description_pipe << [:finally, nil]
        elsif description
          description = description.to_s
          if description.start_with?(':')
            # its actually a symbol, probably, but opal cant differentiate
            _add_to_pipe(SUCCESS_TRACK, description)
          else
            _pipe << Array.new(2)
          end
          _description_pipe << [description, nil]
        end

        @_finally_defined = true
      end

      # step
      def OneStep(description = nil, &block)
        raise "#{self}: OneStep: First, Then or Finally or another OneStep already defined, one_step is for single step operation operations only!" if _pipe.size > 0

        if block_given?
          _add_to_pipe(SUCCESS_TRACK, nil, &block)
          _description_pipe << [:step, nil]
        elsif description
          description = description.to_s
          if description.start_with?(':')
            # its actually a symbol, probably, but opal cant differentiate
            _add_to_pipe(SUCCESS_TRACK, description)
          else
            _pipe << Array.new(2)
          end
          _description_pipe << [description, nil]
        end
      end

      # failed
      def Failed(description, &block)
        raise "#{self}: Failed: No First, Then or Finally or another OneStep defined so far!" unless _pipe.size > 0

        if block_given?
          _add_to_pipe(FAIL_TRACK, nil, &block)
          _description_pipe << [nil, :fail]
        elsif description
          description = description.to_s
          if description.start_with?(':')
            # its actually a symbol, probably, but opal cant differentiate
            _add_to_pipe(FAIL_TRACK, description)
          else
            _pipe << Array.new(2)
          end
          _description_pipe << [nil, description]
        end
      end

      def code_for(description, &block)
        success_entry = [description, nil]
        index = _description_pipe.index(success_entry)
        raise "#{self}: code_for: No First, Then, Finally or OneStep defined for '#{description}'!" unless index
        step = _pipe[index]
        raise "#{self}: code_for: A code block has already been defined for '#{description}'!" if step != [nil, nil]
        _pipe[index] = [block, nil]
      end

      def code_for_failed(description, &block)
        failure_entry = [nil, description]
        index = _description_pipe.index(failure_entry)
        raise "#{self}: code_for_failed: No first, then, finally or one_step defined for '#{description}'!" unless index
        step = _pipe[index]
        raise "#{self}: code_for_failed: A code block has already been defined for '#{description}'!" if step != [nil, nil]
        _pipe[index] = [nil, block]
      end

      def run(*params)
        self.new(*params).run!
      end

      if RUBY_ENGINE == 'opal'
        def process_notification(*params)
          parsed_params = JSON.parse(*params)
          run(parsed_params)
        end

        def process_response(response)
          response.keys.each do |agent_object_id|
            agent = Hyperstack::Transport::RequestAgent.get(agent_object_id)
            agent.result = response[agent_object_id]
          end
        end

        def run_on_server(*params)
          errors = if params.any?
                     validate(*params)
                   else
                     validate({})
                   end
          raise errors.join("\n") if errors.any?
          agent = Hyperstack::Transport::RequestAgent.new
          Hyperstack.client_transport_driver.promise_send(Hyperstack.api_path, { operation: { self.to_s.underscore  => { agent.object_id => JSON.generate(*params) }}} ).then do
            agent.result
          end
        end
      else
        def run_on_client(session_id, *params)
          errors = if params.any?
                      validate(*params)
                    else
                      validate({})
                    end
          raise errors.join("\n") if errors.any?
          Hyperstack::Transport::ServerPubSub.publish_to_session(session_id, { self.to_s.underscore => { Oj.dump(*params) => {}}})
        end

        # def run_on_multiple_clients(sessions, *params)
        #   self.new(*params).run_on_multiple_clients!(sessions)
        # end
        #
        # def run_on_all_clients(*params)
        #   self.new(*params).run_on_all_clients!
        # end
      end

      def validate(params_hash)
        validator.validate(params_hash)
      end

      def _pipe
        @_pipe ||= []
      end

      private

      def _add_to_pipe(track, method_name, &given_block)
        block = if method_name
                  lambda { |*args| send(method_name, *args) }
                else
                  given_block
                end
        step = Array.new(2)
        step[track] = block
        step
        _pipe << step
      end

      def _first_defined?
        @_first_defined ||= false
      end

      def _finally_defined?
        @_finally_defined ||= false
      end

      def _description_pipe
        @_description_pipe ||= []
      end
    end
  end
end