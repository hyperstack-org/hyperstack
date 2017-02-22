module Hyperloop
  class Operation
    class Railway

      def validations
        self.class.validations
      end

      def add_validation_error(i, e)
        @operation.add_error('param validation #{i}', :validation_error, e.to_s)
      end

      class << self
        def validations
          @validations ||= []
        end

        def add_validation(args, block)
          validations << block
        end

        def add_error(param, symbol, message, args, block)
          add_validation(args) do
            begin
              add_error(param, symbol, message) if instance_eval(&block)
            rescue Exit => e
              add_error(param, symbol, message) if e.state == :failed
              raise e
            end
          end
        end
      end

      def process_validations
        validations.each_with_index do |validator, i|
          begin
            next unless @operation.instance_eval(&validator)
            add_validation_error(i, "failed")
          rescue Exit => e
            if e.state != :failed
              add_validation_error(i, "illegal use of succeed! in validation")
            end
            @state = :failed
            @last_result = e.result
            break
          rescue AccessViolation => e
            add_validation_error(i, e)
            @state = :failed
            @last_result = e
            break
          rescue Exception => e
            add_validation_error(i, e)
          end
        end
      end
    end
  end
end
