require 'spec_helper'

describe 'React::Callbacks', js: true do
  it 'defines callback' do
    on_client do
      class Foo
        include React::Callbacks
        define_callback :before_dinner
        before_dinner :wash_hands

        def wash_hands;end
      end
    end

    expect_evaluate_ruby do
      instance = Foo.new
      [ instance.respond_to?(:wash_hands), instance.run_callback(:before_dinner) ]
    end.to eq([true, ["wash_hands"]])
  end

  it 'defines multiple callbacks' do
    on_client do
      class Foo
        include React::Callbacks
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
        instance.run_callback(:before_dinner) ]
    end.to eq([true, true, ["wash_hands", "turn_off_laptop" ]])
  end

  context 'using Hyperloop::Context.reset!' do
    #after(:all) do
    #  Hyperloop::Context.instance_variable_set(:@context, nil)
    #end
    it 'clears callbacks on Hyperloop::Context.reset!' do
      on_client do
        Hyperloop::Context.reset!

        class Foo
          include React::Callbacks
          define_callback :before_dinner

          before_dinner :wash_hands, :turn_off_laptop

          def wash_hands;end

          def turn_off_laptop;end
        end
      end
      expect_evaluate_ruby do
        instance = Foo.new

        Hyperloop::Context.reset!
        
        Foo.class_eval do
          before_dinner :wash_hands
        end

        instance.run_callback(:before_dinner)
      end.to eq(["wash_hands"])
    end
  end

  it 'defines block callback' do
    on_client do
      class Foo
        include React::Callbacks
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
        include React::Callbacks
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
        include React::Callbacks
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
    end.to eq([["eat_ice_cream"], '1-2'])
  end
end
