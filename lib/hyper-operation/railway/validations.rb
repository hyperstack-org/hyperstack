module Hyperloop
  class Operation
    class Railway

      def validations
        self.class.validations
      end

      def add_validation_error(i, e)
        @operation.add_error("param validation #{i+1}", :validation_error, e.to_s)
      end

      class << self
        def validations
          @validations ||= []
        end

        def add_validation(*args, &block)
          validations << block
        end

        def add_error(param, symbol, message, *args, &block)
          add_validation(args) do
            begin
              add_error(param, symbol, message) if instance_eval(&block)
            rescue Exit => e
              raise e unless e.state == :failed
              add_error(param, symbol, message)
              raise Exit.new(:abort_from_add_error, e.result)
            end
          end
        end
      end

      def process_validations
        validations.each_with_index do |validator, i|
          begin
            next if @operation.instance_eval(&validator)
            add_validation_error(i, "param validation #{i+1} failed")
          rescue Exit => e
            case e.state
            when :success
              add_validation_error(i, "illegal use of succeed! in validation")
            when :failed
              add_validation_error(i, "param validation #{i+1} aborted")
            end
            @state = :failed
            @last_result = e.result unless e.result.empty?
            return # break does not work in Opal
          rescue AccessViolation => e
            add_validation_error(i, e)
            @state = :failed
            @last_result = e
            return # break does not work in Opal
          rescue Exception => e
            add_validation_error(i, e)
          end
        end
      end
    end
  end
end
