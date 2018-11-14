require 'spec_helper'

describe 'React::Component', js: true do

  it 'defines react component methods' do
    on_client do
      class Foo
        include Hyperstack::Component
        def initialize(native = nil)
        end

        def render
          Hyperstack::Component::ReactAPI.create_element('div')
        end
      end
    end
    # class methods
    expect_evaluate_ruby("Foo.respond_to?(:initial_state)").to be_truthy
    expect_evaluate_ruby("Foo.respond_to?(:default_props)").to be_truthy
    expect_evaluate_ruby("Foo.respond_to?(:prop_types)").to be_truthy
    # instance_methods
    expect_evaluate_ruby("Foo.new.respond_to?(:component_will_mount)").to be_truthy
    expect_evaluate_ruby("Foo.new.respond_to?(:component_did_mount)").to be_truthy
    expect_evaluate_ruby("Foo.new.respond_to?(:component_will_receive_props)").to be_truthy
    expect_evaluate_ruby("Foo.new.respond_to?(:should_component_update?)").to be_truthy
    expect_evaluate_ruby("Foo.new.respond_to?(:component_will_update)").to be_truthy
    expect_evaluate_ruby("Foo.new.respond_to?(:component_did_update)").to be_truthy
    expect_evaluate_ruby("Foo.new.respond_to?(:component_will_unmount)").to be_truthy
  end

  describe 'Life Cycle Methods' do
    before(:each) do
      on_client do
        class Foo
          include Hyperstack::Component
          def self.call_history
            @call_history ||= []
          end
          def render
            Hyperstack::Component::ReactAPI.create_element('div') { 'lorem' }
          end
        end
      end
    end

    it 'invokes `before_mount` registered methods when `componentWillMount()`' do
      mount 'Foo' do
        Foo.class_eval do
          before_mount :bar, :bar2
          def bar; self.class.call_history << "bar"; end
          def bar2; self.class.call_history << "bar2"; end
        end
      end
      expect_evaluate_ruby("Foo.call_history").to eq(["bar", "bar2"])
    end

    it 'invokes `after_mount` registered methods when `componentDidMount()`' do
      mount 'Foo' do
        Foo.class_eval do
          after_mount :bar3, :bar4
          def bar3; self.class.call_history << "bar3"; end
          def bar4; self.class.call_history << "bar4"; end
        end
      end
      expect_evaluate_ruby("Foo.call_history").to eq(["bar3", "bar4"])
    end

    it 'allows multiple class declared life cycle hooker' do
      evaluate_ruby do
        Foo.class_eval do
          before_mount :bar
          def bar; self.class.call_history << "bar"; end
        end

        class FooBar
          include Hyperstack::Component
          after_mount :bar2
          def self.call_history
            @call_history ||= []
          end
          def bar2; self.class.call_history << "bar2"; end
          def render
            Hyperstack::Component::ReactAPI.create_element('div') { 'lorem' }
          end
        end
        instance = Hyperstack::Component::ReactTestUtils.render_component_into_document(Foo)
        instance = Hyperstack::Component::ReactTestUtils.render_component_into_document(FooBar)
      end
      expect_evaluate_ruby("Foo.call_history").to eq(["bar"])
      expect_evaluate_ruby("FooBar.call_history").to eq(["bar2"])
    end

    it 'allows block for life cycle callback' do
      expect_evaluate_ruby do
        Foo.class_eval do
          attr_accessor :foo
          before_mount do
            self.foo = :bar
          end
        end
        instance = Hyperstack::Component::ReactTestUtils.render_component_into_document(Foo)
        instance.foo
      end.to eq('bar')
    end

    it 'invokes :after_error when componentDidCatch' do
      client_option raise_on_js_errors: :off
      mount 'Foo' do
        class ErrorFoo
          include Hyperstack::Component
          param :just
          def render
            raise 'ErrorFoo Error'
          end
        end
        Foo.class_eval do
          def self.get_error
            @@error
          end

          def self.get_info
            @@info
          end

          def render
            DIV { ErrorFoo(just: :a_param) }
          end

          after_error do |error, info|
            @@error = error.message
            @@info = info[:componentStack]
          end
        end
      end
      expect_evaluate_ruby('Foo.get_error').to eq('ErrorFoo Error')
      expect_evaluate_ruby('Foo.get_info').to eq("\n    in ErrorFoo\n    in div\n    in Foo\n    in Hyperstack::Internal::Component::TopLevelRailsComponent")
    end
  end

  describe 'Misc Methods' do
    it 'has a force_update! method' do
      mount 'Foo' do
        class Foo < HyperComponent
          class << self
            attr_accessor :render_counter
            attr_accessor :instance
          end
          before_mount do
            Foo.render_counter = 0
            Foo.instance = self
          end
          def render
            Foo.render_counter += 1
            DIV { "I have been rendered #{Foo.render_counter} times" }
          end
        end
      end
      expect_evaluate_ruby do
        Foo.instance.force_update!
        Foo.render_counter
      end.to eq(2)
    end

    it 'has its force_update! method return itself' do
      mount 'Foo' do
        class Foo < HyperComponent
          class << self
            attr_accessor :instance
          end
          before_mount do
            Foo.instance = self
          end
          def render
            DIV { "I have been rendered" }
          end
        end
      end
      expect_evaluate_ruby('Foo.instance == Foo.instance.force_update!').to be_truthy
    end

    it 'can buffer an element' do
      mount 'Foo' do
        class Bar < HyperComponent
          param :p
          render { DIV { @P.span; children.render } }
        end
        class Foo < HyperComponent
          def render
            Bar.insert_element(p: "param") { "child"}
          end
        end
      end
      expect(page).to have_content("paramchild")
    end

    it 'can create an element without buffering' do
      mount 'Foo' do
        class Bar < HyperComponent
          param :p
          render { SPAN { @P.span; children.render } }
        end
        class Foo < HyperComponent
          before_mount { @e = Bar.create_element(p: "param") { "child" } }
          render { DIV { 2.times { @e.render } } }
        end
      end
      expect(page).to have_content("paramchildparamchild")
    end

    it 'has a class components method' do
      mount 'Foo' do
        class Bar < HyperComponent
          param :id
          render { inspect }
        end
        class Baz < HyperComponent
          param :id
          render { inspect }
        end
        class BarChild < Bar
        end
        class Foo
          include Hyperstack::Component
          def render
            DIV do
              Bar(id: 1)
              Bar(id: 2)
              Baz(id: 3)
              Baz(id: 4)
              BarChild(id: 5)
              BarChild(id: 6)
            end
          end
        end
        module Hyperstack::Component
          def to_s
            "#{self.class.name}#{':' + @Id.to_s if @Id}"
          end
        end
      end
      expect_evaluate_ruby("Hyperstack::Component.mounted_components")
        .to contain_exactly("Hyperstack::Internal::Component::TopLevelRailsComponent", "Foo", "Bar:1", "Bar:2", "Baz:3", "Baz:4", "BarChild:5", "BarChild:6")
      expect_evaluate_ruby("HyperComponent.mounted_components")
        .to contain_exactly("Bar:1", "Bar:2", "Baz:3", "Baz:4", "BarChild:5", "BarChild:6")
      expect_evaluate_ruby("Bar.mounted_components")
        .to contain_exactly("Bar:1", "Bar:2", "BarChild:5", "BarChild:6")
      expect_evaluate_ruby("Baz.mounted_components")
        .to contain_exactly("Baz:3", "Baz:4")
      expect_evaluate_ruby("BarChild.mounted_components")
        .to contain_exactly("BarChild:5", "BarChild:6")
      expect_evaluate_ruby("Foo.mounted_components")
        .to contain_exactly("Foo")
    end
  end

  describe 'state management' do
    before(:each) do
      on_client do
        class Foo
          include Hyperstack::Component
          include Hyperstack::State::Observable
          def render
            DIV { @foo }
          end
        end
      end
    end
    it 'doesnt cause extra render when calling mutate in before_mount' do
      mount 'StateFoo' do
        class StateFoo
          include Hyperstack::Component
          include Hyperstack::State::Observable

          before_mount do
            mutate
          end

          def self.render_count
            @@render_count ||= 0
          end
          def self.incr_render_count
            @@render_count ||= 0
            @@render_count += 1
          end

          def render
            StateFoo.incr_render_count
            Hyperstack::Component::ReactAPI.create_element('div') { 'lorem' }
          end
        end
      end
      expect_evaluate_ruby('StateFoo.render_count').to eq(1)
    end

    it 'doesnt cause extra render when calling mutate in :before_receive_props' do
      mount 'Foo' do
        class StateFoo
          include Hyperstack::Component
          include Hyperstack::State::Observable

          param :drinks

          def self.render_count
            @@render_count ||= 0
          end
          def self.incr_render_count
            @@render_count ||= 0
            @@render_count += 1
          end

          before_receive_props do |new_params|
            mutate
          end

          def render
            StateFoo.incr_render_count
            Hyperstack::Component::ReactAPI.create_element('div') { 'lorem' }
          end
        end

        Foo.class_eval do
          before_mount do
            mutate @foo = 25
          end

          def render
            DIV { StateFoo(drinks: @foo) }
          end

          after_mount do
            mutate @foo = 50
          end
        end
      end
      expect_evaluate_ruby('StateFoo.render_count').to eq(2)
    end
  end

  describe 'Props' do
    describe 'this.props could be accessed through `params` method' do
      before do
        on_client do
          class Foo
            include Hyperstack::Component
          end
        end
      end

      it 'accesses nested params as orignal Ruby object' do
        mount 'Foo', prop: [{foo: 10}] do
          Foo.class_eval do
            param :prop
            def render
              Hyperstack::Component::ReactAPI.create_element('div') { @Prop[0][:foo] }
            end
          end
        end
        expect(page.body[-35..-19]).to include("<div>10</div>")
      end
    end

    describe 'Prop validation' do
      before do
        on_client do
          class Foo
            include Hyperstack::Component
          end
        end
      end

      it 'specifies validation rules using `params` class method' do
        expect_evaluate_ruby do
          Foo.class_eval do
            params do
              requires :foo, type: String
              optional :bar
            end
          end
          Foo.prop_types
        end.to have_key('_componentValidator')
      end

      it 'logs error in warning if validation failed' do
        evaluate_ruby do
          class Lorem; end
          Foo.class_eval do
            params do
              requires :foo
              requires :lorem, type: Lorem
              optional :bar, type: String
            end

            def render; DIV {}; end
          end
          Hyperstack::Component::ReactTestUtils.render_component_into_document(Foo, bar: 10, lorem: Lorem.new)
        end
        expect(page.driver.browser.manage.logs.get(:browser).map { |m| m.message.gsub(/\\n/, "\n") }.to_a.join("\n"))
          .to match(/Warning: Failed prop( type|Type): In component `Foo`\nRequired prop `foo` was not specified\nProvided prop `bar` could not be converted to String/)
      end

      it 'should not log anything if validation pass' do
        evaluate_ruby do
          class Lorem; end
          Foo.class_eval do
            params do
              requires :foo
              requires :lorem, type: Lorem
              optional :bar, type: String
            end

            def render; DIV {}; end
          end
          Hyperstack::Component::ReactTestUtils.render_component_into_document(Foo, foo: 10, bar: '10', lorem: Lorem.new)
        end
        expect(page.driver.browser.manage.logs.get(:browser).map { |m| m.message.gsub(/\\n/, "\n") }.to_a.join("\n")).to_not match(/prop/)
      end
    end

    describe 'Default props' do
      it 'sets default props using validation helper' do
        on_client do
          class Foo
            include Hyperstack::Component
            params do
              optional :foo, default: 'foo'
              optional :bar, default: 'bar'
            end

            def render
              DIV { @Foo + '-' + @Bar}
            end
          end
        end
        mount 'Foo'
        expect(page.body[-40..-19]).to include("<div>foo-bar</div>")
        mount 'Foo', foo: 'lorem'
        expect(page.body[-40..-19]).to include("<div>lorem-bar</div>")
      end
    end
  end

  describe 'Anonymous Component' do
    it "will not generate spurious warning messages" do
      evaluate_ruby do
        foo = Class.new(HyperComponent)
        foo.class_eval do
          def render; "hello" end
        end

        Hyperstack::Component::ReactTestUtils.render_component_into_document(foo)
      end
      expect(page.driver.browser.manage.logs.get(:browser)
        .reject { |entry| entry.to_s.include?("Deprecated feature") }
        .map { |m| m.message.gsub(/\\n/, "\n") }.to_a.join("\n").size)
        .to eq(0)
    end
  end

  describe 'Render Error Handling' do
    it "will generate a message if render returns something other than an Element or a String" do
      mount 'Foo' do
        class Foo < HyperComponent
          def render; Hash.new; end
        end
      end
      expect(page.driver.browser.manage.logs.get(:browser).map { |m| m.message.gsub(/\\n/, "\n") }.to_a.join("\n"))
          .to match(/You may need to convert this to a string./)
    end
    it "will generate a message if render returns a Component class" do
      mount 'Foo' do
        class Foo < HyperComponent
          def render; Foo; end
        end
      end
      expect(page.driver.browser.manage.logs.get(:browser).map { |m| m.message.gsub(/\\n/, "\n") }.to_a.join("\n"))
        .to match(/Did you mean Foo()/)
    end
    it "will generate a message if more than 1 element is generated" do
      mount 'Foo' do
        class Foo < HyperComponent
          def render; "hello".span; "goodby".span; end
        end
      end
      expect(page.driver.browser.manage.logs.get(:browser).map { |m| m.message.gsub(/\\n/, "\n") }.to_a.join("\n"))
        .to match(/Do you want to wrap your elements in a div?/)
    end
    it "will generate a message if the element generated is not the element returned" do
      mount 'Foo' do
        class Foo < HyperComponent
          def render; "hello".span; "goodby".span.delete; end
        end
      end
      expect(page.driver.browser.manage.logs.get(:browser).map { |m| m.message.gsub(/\\n/, "\n") }.to_a.join("\n"))
        .to match(/Possibly improper use of Element#delete./)
    end
  end

  describe '#render' do
    it 'supports element building helpers' do
      on_client do
        class Foo
          include Hyperstack::Component
          param :foo
          def render
            DIV do
              SPAN { @Foo }
            end
          end
        end

        class Bar
          include Hyperstack::Component
          def render
            DIV do
              Hyperstack::Internal::Component::RenderingContext.render(Foo, foo: 'astring')
            end
          end
        end
      end
      evaluate_ruby do
        Hyperstack::Component::ReactTestUtils.render_component_into_document(Bar)
      end
      expect(page.body[-80..-19]).to include("<div><div><span>astring</span></div></div>")
    end

    it 'builds single node in top-level render without providing a block' do
      mount 'Foo' do
        class Foo
          include Hyperstack::Component

          def render
            DIV()
          end
        end
      end
      expect(page.body).to include('<div data-react-class="Hyperstack.Internal.Component.TopLevelRailsComponent" data-react-props="{&quot;render_params&quot;:{},&quot;component_name&quot;:&quot;Foo&quot;,&quot;controller&quot;:&quot;HyperstackTest&quot;}"><div></div></div>')
    end
  end

  describe 'new react 15/16 custom isMounted implementation' do
    it 'returns true if after mounted' do
      expect_evaluate_ruby do
        class Foo
          include Hyperstack::Component

          def render
            Hyperstack::Component::ReactAPI.create_element('div')
          end
        end

        component = Hyperstack::Component::ReactTestUtils.render_component_into_document(Foo)
        component.mounted?
      end.to eq(true)
    end
  end

  describe '.params_changed?' do

    before(:each) do
      on_client do
        class Foo < HyperComponent
          def needs_update?(next_params, next_state)
            next_params.changed?
          end
        end
      end
    end

    it "returns false if new and old params are the same" do
      expect_evaluate_ruby do
        @foo = Foo.new(nil)
        @foo.instance_eval { @native.JS[:props] = JS.call(:eval, 'function bla(){return {value1: 1, value2: 2};}bla();') }
        @foo.should_component_update?({ value2: 2, value1: 1 }, {})
      end.to be_falsy
    end

    it "returns true if new and old params are have different values" do
      expect_evaluate_ruby do
        @foo = Foo.new(nil)
        @foo.instance_eval { @native.JS[:props] = JS.call(:eval, 'function bla(){return {value1: 1, value2: 2};}bla();') }
        @foo.should_component_update?({value2: 2, value1: 2}, {})
      end.to be_truthy
    end

    it "returns true if new and old params are have different keys" do
      expect_evaluate_ruby do
        @foo = Foo.new(nil)
        @foo.instance_eval { @native.JS[:props] = JS.call(:eval, 'function bla(){return {value1: 1, value2: 2};}bla();') }
        @foo.should_component_update?({value2: 2, value1: 1, value3: 3}, {})
      end.to be_truthy
    end
  end

  describe '#should_component_update?' do

    before(:each) do
      on_client do
        class Foo < HyperComponent
          def needs_update?(next_params, next_state)
            next_state.changed?
          end
        end

        EMPTIES = [`{}`, `undefined`, `null`, `false`]
      end
    end

    it "returns false if both new and old states are empty" do
      expect_evaluate_ruby do
        @foo = Foo.new(nil)
        return_values = []
        EMPTIES.each do |empty1|
          EMPTIES.each do |empty2|
            @foo.instance_eval { @native.JS[:state] = JS.call(:eval, "function bla(){return #{empty1};}bla();") }
            return_values << @foo.should_component_update?({}, Hash.new(empty2))
          end
        end
        return_values
      end.to all( be_falsy )
    end

    it "returns true if old state is empty, but new state is not" do
      expect_evaluate_ruby do
        @foo = Foo.new(nil)
        return_values = []
        EMPTIES.each do |empty|
          @foo.instance_eval { @native.JS[:state] = JS.call(:eval, "function bla(){return #{empty};}bla();") }
          return_values << @foo.should_component_update?({}, {foo: 12})
        end
        return_values
      end.to all( be_truthy )
    end

    it "returns true if new state is empty, but old state is not" do
      expect_evaluate_ruby do
        @foo = Foo.new(nil)
        return_values = []
        EMPTIES.each do |empty|
          @foo.instance_eval { @native.JS[:state] = JS.call(:eval, "function bla(){return {foo: 12};}bla();") }
          return_values << @foo.should_component_update?({}, Hash.new(empty))
        end
        return_values
      end.to all( be_truthy )
    end

    it "returns true if new state and old state have different time stamps" do
      expect_evaluate_ruby do
        @foo = Foo.new(nil)
        return_values = []
        EMPTIES.each do |empty|
          @foo.instance_eval { @native.JS[:state] = JS.call(:eval, "function bla(){return {'***_state_updated_at-***': 12};}bla();") }
          return_values << @foo.should_component_update?({}, {'***_state_updated_at-***' => 13})
        end
        return_values
      end.to all ( be_truthy )
    end

    it "returns false if new state and old state have the same time stamps" do
      expect_evaluate_ruby do
        @foo = Foo.new(nil)
        return_values = []
        EMPTIES.each do |empty|
          @foo.instance_eval { @native.JS[:state] = JS.call(:eval, "function bla(){return {'***_state_updated_at-***': 12};}bla();") }
          return_values << @foo.should_component_update?({}, {'***_state_updated_at-***' => 12})
        end
        return_values
      end.to all( be_falsy )
    end

    it "returns true if new state without timestamp is different from old state" do
      expect_evaluate_ruby do
        @foo = Foo.new(nil)
        return_values = []
        EMPTIES.each do |empty|
          @foo.instance_eval { @native.JS[:state] = JS.call(:eval, "function bla(){return {'my_state': 12};}bla();") }
          return_values << @foo.should_component_update?({}, {'my-state' => 13})
        end
        return_values
      end.to all ( be_truthy )
    end

    it "returns false if new state without timestamp is the same as old state" do
      expect_evaluate_ruby do
        @foo = Foo.new(nil)
        return_values = []
        EMPTIES.each do |empty|
          @foo.instance_eval { @native.JS[:state] = JS.call(:eval, "function bla(){return {'my_state': 12};}bla();") }
          return_values << @foo.should_component_update?({}, {'my_state' => 12})
        end
        return_values
      end.to all( be_falsy )
    end
  end

  describe '#children' do
    before(:each) do
      on_client do
        class Foo
          include Hyperstack::Component
          def render
            Hyperstack::Component::ReactAPI.create_element('div') { 'lorem' }
          end
        end
      end
    end

    it 'returns Hyperstack::Component::Children collection with child elements' do
      evaluate_ruby do
        ele = Hyperstack::Component::ReactAPI.create_element(Foo) {
          [Hyperstack::Component::ReactAPI.create_element('a'), Hyperstack::Component::ReactAPI.create_element('li')]
        }
        instance = Hyperstack::Component::ReactTestUtils.render_into_document(ele)

        CHILDREN = instance.children
      end
      expect_evaluate_ruby("CHILDREN.class.name").to eq('Hyperstack::Component::Children')
      expect_evaluate_ruby("CHILDREN.count").to eq(2)
      expect_evaluate_ruby("CHILDREN.map(&:element_type)").to eq(['a', 'li'])
    end

    it 'returns an empty Enumerator if there are no children' do
      evaluate_ruby do
        ele = Hyperstack::Component::ReactAPI.create_element(Foo)
        instance = Hyperstack::Component::ReactTestUtils.render_into_document(ele)
        NODES = instance.children.each
      end
      expect_evaluate_ruby("NODES.size").to eq(0)
      expect_evaluate_ruby("NODES.count").to eq(0)
    end
  end
end
