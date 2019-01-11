require 'spec_helper'

describe 'Hyperstack::Internal::Callbacks', js: true do
  it 'defines callback' do
    class Foo
      include Hyperstack::Internal::Callbacks
      define_callback :before_dinner
      before_dinner :wash_hands

      def wash_hands;end
    end

    instance = Foo.new
    expect(instance).to respond_to(:wash_hands)
    expect(instance).to receive(:wash_hands)
    expect(instance.run_callback(:before_dinner, 1, 2, 3)).to eq([1, 2, 3])
  end

  # TODO: move all these to run on server as above

  it 'defines multiple callbacks' do
    on_client do
      class Foo
        include Hyperstack::Internal::Callbacks
        define_callback :before_dinner
        before_dinner :wash_hands, :turn_off_laptop

        def wash_hands;end
        def turn_off_laptop;end
      end
    end
    expect_evaluate_ruby do
      instance = Foo.new
      [ instance.respond_to?(:wash_hands),
        instance.respond_to?(:turn_off_laptop),
        instance.run_callback(:before_dinner, 1, 2, 3) ]
    end.to eq([true, true, [1, 2, 3]])
  end

  context 'using Hyperloop::Context.reset!' do
    #after(:all) do
    #  Hyperloop::Context.instance_variable_set(:@context, nil)
    #end
    it 'clears callbacks on Hyperloop::Context.reset!' do
      on_client do
        Hyperstack::Context.reset!

        class Foo
          include Hyperstack::Internal::Callbacks
          define_callback :before_dinner

          before_dinner :wash_hands, :turn_off_laptop

          def wash_hands;end

          def turn_off_laptop;end
        end
      end
      expect_evaluate_ruby do
        instance = Foo.new

        Hyperstack::Context.reset!

        Foo.class_eval do
          before_dinner :wash_hands
        end

        instance.run_callback(:before_dinner, 1, 2, 3)
      end.to eq([1, 2, 3])
    end
  end

  it 'defines block callback' do
    on_client do
      class Foo
        include Hyperstack::Internal::Callbacks
        attr_accessor :a
        attr_accessor :b

        define_callback :before_dinner

        before_dinner do
          self.a = 10
        end
        before_dinner do
          self.b = 20
        end
      end
    end
    expect_evaluate_ruby do
      foo = Foo.new
      foo.run_callback(:before_dinner)
      [ foo.a, foo.b ]
    end.to eq([10, 20])
  end

  it 'defines multiple callback group' do
    on_client do
      class Foo
        include Hyperstack::Internal::Callbacks
        define_callback :before_dinner
        define_callback :after_dinner
        attr_accessor :a

        before_dinner do
          self.a = 10
        end
      end
    end
    expect_evaluate_ruby do
      foo = Foo.new
      foo.run_callback(:before_dinner)
      foo.run_callback(:after_dinner)
      foo.a
    end.to eq(10)
  end

  it 'receives args as callback' do
    on_client do
      class Foo
        include Hyperstack::Internal::Callbacks
        define_callback :before_dinner
        define_callback :after_dinner

        attr_accessor :lorem

        before_dinner do |a, b|
          self.lorem  = "#{a}-#{b}"
        end

        after_dinner :eat_ice_cream
        def eat_ice_cream(a,b,c);  end
      end
    end
    expect_evaluate_ruby do
      foo = Foo.new
      foo.run_callback(:before_dinner, 1, 2)
      res1 = foo.run_callback(:after_dinner, 4, 5, 6)
      [res1, foo.lorem]
    end.to eq([[4, 5, 6], '1-2'])
  end
end
