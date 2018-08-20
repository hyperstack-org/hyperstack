module Hyperstack
  class Business
    module Mixin
      def self.included(base)
        base.include(Hyperstack::Params::InstanceMethods)
        base.extend(Hyperstack::Params::ClassMethods)
        base.extend(Hyperstack::Business::ClassMethods)
      end

      attr_accessor :props

      def initialize(*params)
        @on_fail_track = false
        @props = self.class.validator.default_props
        errors = if params.any?
                   self.class.validator.validate(*params)
                 else
                   self.class.validator.validate({})
                 end
        raise errors.join("\n") if errors.any?
        @props.merge!(*params) if params.any?
        @last_result = Promise.new.resolve(@props)
      end

      def run!
        if RUBY_ENGINE == 'opal'
          _opal_run!
        else
          _ruby_run!
        end
      end

      private

      if RUBY_ENGINE == 'opal'
        def _opal_run!
          # TODO do setTimeout here
          # TODO or/and support webworkers
          _common_run!
        end
      else
        def _ruby_run!
          # TODO do eventmachine delay here
          _common_run!
        end
      end

      def _common_run!
        # TODO make this properly work with promises as results of each step
        promise = Promise.new
        self.class._pipe.each do |step|
          @last_result = @last_result.then do |*args|
            _run_step(step, *args)
          end.fail do |*args|
            @on_fail_track = true
            _run_step(step, *args)
          end
        end
        @last_result.then do |*args|
          if @on_fail_track
            promise.reject(args)
          else
            promise.resolve(args)
          end
        end.fail do |*args|
          promise.reject(args)
        end
        promise
      end

      def _run_step(step, *args)
        block = if @on_fail_track
                  step[1]
                else
                  step[0]
                end

        if block
          if block.arity.zero?
            instance_exec(&block)
          else
            instance_exec(*args, &block)
          end
        else
          args
        end
      end
    end
  end
end
