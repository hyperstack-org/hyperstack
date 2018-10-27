module Hyperstack
  module Internal
    module AutoUnmount
      def self.included(base)
        base.include(Hyperstack::Internal::Callbacks)
        base.class_eval do
          define_callback :before_unmount
        end
      end

      def unmount
        run_callback(:before_unmount)
        AutoUnmount.objects_to_unmount[self].each(&:unmount)
        AutoUnmount.objects_to_unmount.delete(self)
        instance_variables.each do |var|
          val = instance_variable_get(var)
          begin
            val.unmount if val.respond_to?(:unmount)
          rescue RUBY_ENGINE == 'opal' ? JS::Error : nil
            nil
          end
        end
      end

      def every(*args, &block)
        super.tap do |id|
          sself = self
          id.define_singleton_method(:unmount) { abort }
          id.define_singleton_method(:manually_unmount) do
            AutoUnmount.objects_to_unmount[sself].delete(id)
          end
          AutoUnmount.objects_to_unmount[self] << id
        end
      end

      def after(*args, &block)
        super.tap do |id|
          sself = self
          id.define_singleton_method(:unmount) { abort }
          id.define_singleton_method(:manually_unmount) do
            AutoUnmount.objects_to_unmount[sself].delete(id)
          end
          AutoUnmount.objects_to_unmount[self] << id
        end
      end

      def receives(broadcaster, *args, &block)
        broadcaster.receiver(self, *args, &block).tap do |id|
          # TODO: broadcaster classes should already defined manually_unmount
          # id.define_singleton_method(:manually_unmount) do
          #   AutoUnmount.objects_to_unmount[self].delete(id)
          # end
          AutoUnmount.objects_to_unmount[self] << id
        end
      end
      class << self
        def objects_to_unmount
          @objects_to_unmount ||= Hash.new { |h, k| h[k] = Set.new }
        end
      end
    end
  end
end
