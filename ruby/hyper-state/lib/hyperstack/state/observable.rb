module Hyperstack
  module State
    module Observable
      def self.bulk_update(&block)
        Internal::State::Mapper.bulk_update(&block)
      end

      def self.included(base)
        base.include Internal::AutoUnmount
        %i[singleton_method method].each do |kind|
          base.send(:"define_#{kind}", :receives) do |*args, &block|
            Internal::Receiver.mount(self, *args, &block)
          end
          base.send(:"define_#{kind}", :observe) do |&block|
            result = block.call if block
            Internal::State::Mapper.observed! self
            result
          end
          base.send(:"define_#{kind}", :mutate) do |*_args, &block|
            # any args will be ignored thus allowing us to say `mutate @foo = 123, @bar[:x] = 7` etc
            result = block.call if block
            Internal::State::Mapper.mutated! self
            result
          end
          if RUBY_ENGINE == 'opal'
            base.send(:"define_#{kind}", :set) do |var|
              lambda do |val|
                `self[#{var}] = #{val}`
                mutate if var =~ /^[a-z]/
              end
            end
          else
            base.send(:"define_#{kind}", :set) do |var|
              lambda do |val|
                instance_variable_set(:"@#{var}", val)
                mutate if var =~ /^[a-z]/
              end
            end
          end
          base.singleton_class.send(:"define_#{kind}", :observer) do |name, &block|
            define_method(name) do |*args|
              instance_exec(*args, &block).tap do
                Internal::State::Mapper.observed! self
              end
            end
          end
          base.singleton_class.send(:"define_#{kind}", :mutator) do |name, &block|
            define_method(name) do |*args|
              instance_exec(*args, &block).tap do
                Internal::State::Mapper.mutated! self
              end
            end
          end
          base.singleton_class.send(:"define_#{kind}", :state_reader) do |*names|
            names.each do |name|
              define_method(name) do
                instance_variable_get(:"@#{name}").tap { Internal::State::Mapper.observed!(self) }
              end
            end
          end
          base.singleton_class.send(:"define_#{kind}", :state_writer) do |*names|
            names.each do |name|
              define_method(:"#{name}=") do |x|
                instance_variable_set(:"@#{name}", x).tap { Internal::State::Mapper.mutated!(self) }
              end
            end
          end
          base.singleton_class.send(:"define_#{kind}", :state_accessor) do |*names|
            state_reader(*names)
            state_writer(*names)
          end
        end
      end
    end
  end
end
