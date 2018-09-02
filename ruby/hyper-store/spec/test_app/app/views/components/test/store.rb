module Test
  class Store < Hyperloop::Store
    class << self
      state singleton_klass: 'SC', reader: true
      state singleton_instance: 'SI', scope: :instance, reader: true
      state singleton_shared: 'SS', scope: :shared, reader: true
      state :class_foo, initializer: :bar

      def bar
        'self.bar'
      end
    end
    state class_class: 'CC', scope: :class, reader: true
    state class_instance: 'CI', reader: true
    state class_shared: 'CS', scope: :shared, reader: true
    state :instance_foo, initializer: :bar

    def bar
      'bar'
    end
  end
end
