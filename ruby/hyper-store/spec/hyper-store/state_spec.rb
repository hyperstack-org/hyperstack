require 'spec_helper'

# rubocop:disable Metrics/BlockLength
describe 'StateWrapper' do
  context 'methods', js: true do
    context 'state and mutate' do
      context 'declared at the class level' do
        it 'will rerender a component when an instance state is mutated' do
          mount 'Test::App'

          expect(find('#sci')).to have_content('CI')
          click_button('mci')
          expect(find('#sci')).to have_content('CI x')
        end

        it 'will rerender a component when a class state is mutated' do
          mount 'Test::App'

          expect(find('#scc')).to have_content('CC')
          click_button('mcc')
          expect(find('#scc')).to have_content('CC x')
        end

        it 'will rerender a component when a shared state is mutated' do
          mount 'Test::App'

          expect(find('#scs')).to have_content('CS')
          click_button('mcs')
          expect(find('#scs')).to have_content('CS x')
        end
      end

      context 'declared at the singleton class level' do
        it 'will rerender a component when an instance state is mutated' do
          mount 'Test::App'

          expect(find('#ssi')).to have_content('SI')
          click_button('msi')
          expect(find('#ssi')).to have_content('SI x')
        end

        it 'will rerender a component when a class state is mutated' do
          mount 'Test::App'

          expect(find('#ssc')).to have_content('SC')
          click_button('msc')
          expect(find('#ssc')).to have_content('SC x')
        end

        it 'will rerender a component when a shared state is mutated' do
          mount 'Test::App'

          expect(find('#sss')).to have_content('SS')
          click_button('mss')
          expect(find('#sss')).to have_content('SS x')
        end
      end
    end
  end

  context 'macros' do
    context 'state' do
      context 'component test', js: true do
        context 'with an initial value' do
          context 'of type' do
            it 'nil' do
              mount 'App' do
                class Foo < Hyperloop::Store
                  state bar: nil
                end
                class App < React::Component::Base
                  before_mount do
                    @foo = Foo.new
                  end

                  render(DIV) do
                    H1 { "@foo.state.bar: #{@foo.state.bar.inspect}" }
                  end
                end
              end
              expect(page).to have_content('@foo.state.bar: nil')
            end

            it 'string' do
              mount 'App' do
                class Foo < Hyperloop::Store
                  state bar: 'a state value'
                end
                class App < React::Component::Base
                  before_mount do
                    @foo = Foo.new
                  end

                  render(DIV) do
                    H1 { "@foo.state.bar: #{@foo.state.bar}" }
                  end
                end
              end

              expect(page).to have_content('@foo.state.bar: a state value')
            end

            it 'boolean' do
              mount 'App' do
                class Foo < Hyperloop::Store
                  state bar: true
                end
                class App < React::Component::Base
                  before_mount do
                    @foo = Foo.new
                  end

                  render(DIV) do
                    H1 { "@foo.state.bar: #{@foo.state.bar}" }
                  end
                end
              end

              expect(page).to have_content('@foo.state.bar: true')
            end

            it 'integer' do
              mount 'App' do
                class Foo < Hyperloop::Store
                  state bar: 30
                end
                class App < React::Component::Base
                  before_mount do
                    @foo = Foo.new
                  end

                  render(DIV) do
                    H1 { "@foo.state.bar: #{@foo.state.bar}" }
                  end
                end
              end

              expect(page).to have_content('@foo.state.bar: 30')
            end

            it 'decimal' do
              mount 'App' do
                class Foo < Hyperloop::Store
                  state bar: 30.0
                end
                class App < React::Component::Base
                  before_mount do
                    @foo = Foo.new
                  end

                  render(DIV) do
                    H1 { "@foo.state.bar: #{@foo.state.bar}" }
                  end
                end
              end

              expect(page).to have_content('@foo.state.bar: 30')
            end

            it 'array' do
              mount 'App' do
                class Foo < Hyperloop::Store
                  state bar: ['30', 30, 30.0]
                end
                class App < React::Component::Base
                  before_mount do
                    @foo = Foo.new
                  end

                  render(DIV) do
                    H1 { "@foo.state.bar: #{@foo.state.bar}" }
                  end
                end
              end

              expect(page).to have_content('@foo.state.bar: 30,30,30')
            end

            it 'hash' do
              mount 'App' do
                class Foo < Hyperloop::Store
                  state bar: { string: '30', integer: 30, decimal: 30.0 }
                end
                class App < React::Component::Base
                  before_mount do
                    @foo = Foo.new
                  end

                  render(DIV) do
                    H1 { "@foo.state.bar: #{@foo.state.bar}" }
                  end
                end
              end

              expect(page)
                .to have_content('@foo.state.bar: {"string"=>"30", "integer"=>30, "decimal"=>30}')
            end

            it 'class instance' do
              mount 'App' do
                class Bar
                  def to_s
                    'Bar'
                  end
                end

                class Foo < Hyperloop::Store
                  state bar: Bar.new
                end
                class App < React::Component::Base
                  before_mount do
                    @foo = Foo.new
                  end

                  render(DIV) do
                    H1 { "@foo.state.bar: #{@foo.state.bar}" }
                  end
                end
              end

              expect(page)
                .to have_content('@foo.state.bar: Bar')
            end
          end

          context 'declared in the class level' do
            context 'for shared states' do
              it 'can be declared as the value of the name key in the hash' do
                mount 'App' do
                  class Foo < Hyperloop::Store
                    state bar: 'a state value', scope: :shared
                  end
                  class App < React::Component::Base
                    before_mount do
                      @foo = Foo.new
                    end

                    render(DIV) do
                      H1 { "Foo.state.bar: #{Foo.state.bar}" }
                      H1 { "@foo.state.bar: #{@foo.state.bar}" }
                    end
                  end
                end

                expect(page).to have_content('Foo.state.bar: a state value')
                expect(page).to have_content('@foo.state.bar: a state value')
              end

              it 'can be declared with \'initializer: Symbol\'' do
                mount 'App' do
                  class Foo < Hyperloop::Store
                    state :bar, scope: :shared, initializer: :baz

                    def self.baz
                      'a state value'
                    end
                  end
                  class App < React::Component::Base
                    before_mount do
                      @foo = Foo.new
                    end

                    render(DIV) do
                      H1 { "Foo.state.bar: #{Foo.state.bar}" }
                      H1 { "@foo.state.bar: #{@foo.state.bar}" }
                    end
                  end
                end

                expect(page).to have_content('Foo.state.bar: a state value')
                expect(page).to have_content('@foo.state.bar: a state value')
              end

              it 'can be declared with \'initializer: Proc\'' do
                mount 'App' do
                  class Foo < Hyperloop::Store
                    state :bar, scope: :shared, initializer: -> { 'a state value' }
                  end
                  class App < React::Component::Base
                    before_mount do
                      @foo = Foo.new
                    end

                    render(DIV) do
                      H1 { "Foo.state.bar: #{Foo.state.bar}" }
                      H1 { "@foo.state.bar: #{@foo.state.bar}" }
                    end
                  end
                end

                expect(page).to have_content('Foo.state.bar: a state value')
                expect(page).to have_content('@foo.state.bar: a state value')
              end

              it 'can be declared with a block' do
                mount 'App' do
                  class Foo < Hyperloop::Store
                    state :bar, scope: :shared do
                      'a state value'
                    end
                  end
                  class App < React::Component::Base
                    before_mount do
                      @foo = Foo.new
                    end

                    render(DIV) do
                      H1 { "Foo.state.bar: #{Foo.state.bar}" }
                      H1 { "@foo.state.bar: #{@foo.state.bar}" }
                    end
                  end
                end

                expect(page).to have_content('Foo.state.bar: a state value')
                expect(page).to have_content('@foo.state.bar: a state value')
              end
            end

            context 'for class states' do
              it 'can be declared as the value of the name key in the hash' do
                mount 'App' do
                  class Foo < Hyperloop::Store
                    state bar: 'a state value', scope: :class
                  end
                  class App < React::Component::Base
                    render(DIV) do
                      H1 { "Foo.state.bar: #{Foo.state.bar}" }
                    end
                  end
                end

                expect(page).to have_content('Foo.state.bar: a state value')
              end

              it 'can be declared with \'initializer: Symbol\'' do
                mount 'App' do
                  class Foo < Hyperloop::Store
                    state :bar, scope: :class, initializer: :baz

                    def self.baz
                      'a state value'
                    end
                  end
                  class App < React::Component::Base
                    render(DIV) do
                      H1 { "Foo.state.bar: #{Foo.state.bar}" }
                    end
                  end
                end

                expect(page).to have_content('Foo.state.bar: a state value')
              end

              it 'can be declared with \'initializer: Proc\'' do
                mount 'App' do
                  class Foo < Hyperloop::Store
                    state :bar, scope: :class, initializer: -> { 'a state value' }
                  end
                  class App < React::Component::Base
                    render(DIV) do
                      H1 { "Foo.state.bar: #{Foo.state.bar}" }
                    end
                  end
                end

                expect(page).to have_content('Foo.state.bar: a state value')
              end

              it 'can be declared with a block' do
                mount 'App' do
                  class Foo < Hyperloop::Store
                    state :bar, scope: :class do
                      'a state value'
                    end
                  end
                  class App < React::Component::Base
                    render(DIV) do
                      H1 { "Foo.state.bar: #{Foo.state.bar}" }
                    end
                  end
                end

                expect(page).to have_content('Foo.state.bar: a state value')
              end
            end

            context 'for instance states' do
              it 'can be declared as the value of the name key in the hash' do
                mount 'App' do
                  class Foo < Hyperloop::Store
                    state bar: 'a state value'
                  end
                  class App < React::Component::Base
                    before_mount do
                      @foo = Foo.new
                    end

                    render(DIV) do
                      H1 { "@foo.state.bar: #{@foo.state.bar}" }
                    end
                  end
                end

                expect(page).to have_content('@foo.state.bar: a state value')
              end

              it 'can be declared with \'initializer: Symbol\'' do
                mount 'App' do
                  class Foo < Hyperloop::Store
                    state :bar, initializer: :baz

                    def baz
                      'a state value'
                    end
                  end
                  class App < React::Component::Base
                    before_mount do
                      @foo = Foo.new
                    end

                    render(DIV) do
                      H1 { "@foo.state.bar: #{@foo.state.bar}" }
                    end
                  end
                end

                expect(page).to have_content('@foo.state.bar: a state value')
              end

              it 'can be declared with \'initializer: Proc\'' do
                mount 'App' do
                  class Foo < Hyperloop::Store
                    state :bar, initializer: -> { 'a state value' }
                  end
                  class App < React::Component::Base
                    before_mount do
                      @foo = Foo.new
                    end

                    render(DIV) do
                      H1 { "@foo.state.bar: #{@foo.state.bar}" }
                    end
                  end
                end

                expect(page).to have_content('@foo.state.bar: a state value')
              end

              it 'can be declared with a block' do
                mount 'App' do
                  class Foo < Hyperloop::Store
                    state :bar do
                      'a state value'
                    end
                  end
                  class App < React::Component::Base
                    before_mount do
                      @foo = Foo.new
                    end

                    render(DIV) do
                      H1 { "@foo.state.bar: #{@foo.state.bar}" }
                    end
                  end
                end

                expect(page).to have_content('@foo.state.bar: a state value')
              end
            end
          end

          context 'declared in the singleton class level' do
            context 'for shared states' do
              it 'can be declared as the value of the name key in the hash' do
                mount 'App' do
                  class Foo < Hyperloop::Store
                    class << self
                      state bar: 'a state value', scope: :shared
                    end
                  end
                  class App < React::Component::Base
                    before_mount do
                      @foo = Foo.new
                    end

                    render(DIV) do
                      H1 { "Foo.state.bar: #{Foo.state.bar}" }
                      H1 { "@foo.state.bar: #{@foo.state.bar}" }
                    end
                  end
                end

                expect(page).to have_content('Foo.state.bar: a state value')
                expect(page).to have_content('@foo.state.bar: a state value')
              end

              it 'can be declared with \'initializer: Symbol\'' do
                mount 'App' do
                  class Foo < Hyperloop::Store
                    class << self
                      state :bar, scope: :shared, initializer: :baz

                      def baz
                        'a state value'
                      end
                    end
                  end
                  class App < React::Component::Base
                    before_mount do
                      @foo = Foo.new
                    end

                    render(DIV) do
                      H1 { "Foo.state.bar: #{Foo.state.bar}" }
                      H1 { "@foo.state.bar: #{@foo.state.bar}" }
                    end
                  end
                end

                expect(page).to have_content('Foo.state.bar: a state value')
                expect(page).to have_content('@foo.state.bar: a state value')
              end

              it 'can be declared with \'initializer: Proc\'' do
                mount 'App' do
                  class Foo < Hyperloop::Store
                    class << self
                      state :bar, scope: :shared, initializer: -> { 'a state value' }
                    end
                  end
                  class App < React::Component::Base
                    before_mount do
                      @foo = Foo.new
                    end

                    render(DIV) do
                      H1 { "Foo.state.bar: #{Foo.state.bar}" }
                      H1 { "@foo.state.bar: #{@foo.state.bar}" }
                    end
                  end
                end

                expect(page).to have_content('Foo.state.bar: a state value')
                expect(page).to have_content('@foo.state.bar: a state value')
              end

              it 'can be declared with a block' do
                mount 'App' do
                  class Foo < Hyperloop::Store
                    class << self
                      state :bar, scope: :shared do
                        'a state value'
                      end
                    end
                  end
                  class App < React::Component::Base
                    before_mount do
                      @foo = Foo.new
                    end

                    render(DIV) do
                      H1 { "Foo.state.bar: #{Foo.state.bar}" }
                      H1 { "@foo.state.bar: #{@foo.state.bar}" }
                    end
                  end
                end

                expect(page).to have_content('Foo.state.bar: a state value')
                expect(page).to have_content('@foo.state.bar: a state value')
              end
            end

            context 'for class states' do
              it 'can be declared as the value of the name key in the hash' do
                mount 'App' do
                  class Foo < Hyperloop::Store
                    class << self
                      state bar: 'a state value'
                    end
                  end
                  class App < React::Component::Base
                    render(DIV) do
                      H1 { "Foo.state.bar: #{Foo.state.bar}" }
                    end
                  end
                end

                expect(page).to have_content('Foo.state.bar: a state value')
              end

              it 'can be declared with \'initializer: Symbol\'' do
                mount 'App' do
                  class Foo < Hyperloop::Store
                    class << self
                      state :bar, initializer: :baz

                      def baz
                        'a state value'
                      end
                    end
                  end
                  class App < React::Component::Base
                    render(DIV) do
                      H1 { "Foo.state.bar: #{Foo.state.bar}" }
                    end
                  end
                end

                expect(page).to have_content('Foo.state.bar: a state value')
              end

              it 'can be declared with \'initializer: Proc\'' do
                mount 'App' do
                  class Foo < Hyperloop::Store
                    class << self
                      state :bar, initializer: -> { 'a state value' }
                    end
                  end
                  class App < React::Component::Base
                    render(DIV) do
                      H1 { "Foo.state.bar: #{Foo.state.bar}" }
                    end
                  end
                end

                expect(page).to have_content('Foo.state.bar: a state value')
              end

              it 'can be declared with a block' do
                mount 'App' do
                  class Foo < Hyperloop::Store
                    class << self
                      state :bar do
                        'a state value'
                      end
                    end
                  end
                  class App < React::Component::Base
                    render(DIV) do
                      H1 { "Foo.state.bar: #{Foo.state.bar}" }
                    end
                  end
                end

                expect(page).to have_content('Foo.state.bar: a state value')
              end
            end

            context 'for instance states' do
              it 'can be declared as the value of the name key in the hash' do
                mount 'App' do
                  class Foo < Hyperloop::Store
                    class << self
                      state bar: 'a state value', scope: :instance
                    end
                  end
                  class App < React::Component::Base
                    before_mount do
                      @foo = Foo.new
                    end

                    render(DIV) do
                      H1 { "@foo.state.bar: #{@foo.state.bar}" }
                    end
                  end
                end

                expect(page).to have_content('@foo.state.bar: a state value')
              end

              it 'can be declared with \'initializer: Symbol\'' do
                mount 'App' do
                  class Foo < Hyperloop::Store
                    class << self
                      state :bar, scope: :instance, initializer: :baz
                    end

                    def baz
                      'a state value'
                    end
                  end
                  class App < React::Component::Base
                    before_mount do
                      @foo = Foo.new
                    end

                    render(DIV) do
                      H1 { "@foo.state.bar: #{@foo.state.bar}" }
                    end
                  end
                end

                expect(page).to have_content('@foo.state.bar: a state value')
              end

              it 'can be declared with \'initializer: Proc\'' do
                mount 'App' do
                  class Foo < Hyperloop::Store
                    class << self
                      state :bar, scope: :instance, initializer: -> { 'a state value' }
                    end
                  end
                  class App < React::Component::Base
                    before_mount do
                      @foo = Foo.new
                    end

                    render(DIV) do
                      H1 { "@foo.state.bar: #{@foo.state.bar}" }
                    end
                  end
                end

                expect(page).to have_content('@foo.state.bar: a state value')
              end

              it 'can be declared with a block' do
                mount 'App' do
                  class Foo < Hyperloop::Store
                    class << self
                      state :bar, scope: :instance do
                        'a state value'
                      end
                    end
                  end
                  class App < React::Component::Base
                    before_mount do
                      @foo = Foo.new
                    end

                    render(DIV) do
                      H1 { "@foo.state.bar: #{@foo.state.bar}" }
                    end
                  end
                end

                expect(page).to have_content('@foo.state.bar: a state value')
              end
            end
          end
        end
      end
      context 'unit test' do
        after(:each) do
          # There's gotta be a better way to deal with this
          Object.send(:remove_const, :Foo)

          # We're very basically mocking React::State so we can run these outside of Opal
          React::State.reset!
        end

        context 'with an initial value' do
          context 'declared in the class level' do
            context 'for shared states' do
              it 'can be declared as the value of the name key in the hash' do
                class Foo < Hyperloop::Store
                  state bar: 'a state value', scope: :shared
                end
                Hyperloop::Application::Boot.run
                foo = Foo.new

                expect(Foo.state.bar).to eq('a state value')
                expect(foo.state.bar).to eq('a state value')
              end

              it 'can be declared with \'initializer: Symbol\'' do
                class Foo < Hyperloop::Store
                  state :bar, scope: :shared, initializer: :baz

                  def self.baz
                    'a state value'
                  end
                end

                Hyperloop::Application::Boot.run
                foo = Foo.new

                expect(Foo.state.bar).to eq(Foo.baz)
                expect(foo.state.bar).to eq(Foo.baz)
              end

              it 'can be declared with \'initializer: Proc\'' do
                class Foo < Hyperloop::Store
                  state :bar, scope: :shared, initializer: -> { 'a state value' }
                end
                foo = Foo.new
                Hyperloop::Application::Boot.run

                expect(Foo.state.bar).to eq('a state value')
                expect(foo.state.bar).to eq('a state value')
              end

              it 'can be declared with a block' do
                class Foo < Hyperloop::Store
                  state :bar, scope: :shared do
                    'a state value'
                  end
                end
                foo = Foo.new
                Hyperloop::Application::Boot.run

                expect(Foo.state.bar).to eq('a state value')
                expect(foo.state.bar).to eq('a state value')
              end
            end

            context 'for class states' do
              it 'can be declared as the value of the name key in the hash' do
                class Foo < Hyperloop::Store
                  state bar: 'a state value', scope: :class
                end
                Hyperloop::Application::Boot.run

                expect(Foo.state.bar).to eq('a state value')
              end

              it 'can be declared with \'initializer: Symbol\'' do
                class Foo < Hyperloop::Store
                  state :bar, scope: :class, initializer: :baz

                  def self.baz
                    'a state value'
                  end
                end
                Hyperloop::Application::Boot.run

                expect(Foo.state.bar).to eq(Foo.baz)
              end

              it 'can be declared with \'initializer: Proc\'' do
                class Foo < Hyperloop::Store
                  state :bar, scope: :class, initializer: -> { 'a state value' }
                end
                Hyperloop::Application::Boot.run

                expect(Foo.state.bar).to eq('a state value')
              end

              it 'can be declared with a block' do
                class Foo < Hyperloop::Store
                  state :bar, scope: :class do
                    'a state value'
                  end
                end
                Hyperloop::Application::Boot.run

                expect(Foo.state.bar).to eq('a state value')
              end
            end

            context 'for instance states' do
              it 'can be declared as the value of the name key in the hash' do
                class Foo < Hyperloop::Store
                  state bar: 'a state value'
                end
                foo = Foo.new

                expect(foo.state.bar).to eq('a state value')
              end

              it 'can be declared with \'initializer: Symbol\'' do
                class Foo < Hyperloop::Store
                  state :bar, initializer: :baz

                  def baz
                    'a state value'
                  end
                end
                foo = Foo.new

                expect(foo.state.bar).to eq(foo.baz)
              end

              it 'can be declared with \'initializer: Proc\'' do
                class Foo < Hyperloop::Store
                  state :bar, initializer: -> { 'a state value' }
                end
                foo = Foo.new

                expect(foo.state.bar).to eq('a state value')
              end

              it 'can be declared with a block' do
                class Foo < Hyperloop::Store
                  state :bar do
                    'a state value'
                  end
                end
                foo = Foo.new

                expect(foo.state.bar).to eq('a state value')
              end
            end
          end

          context 'declared in the singleton class level' do
            context 'for shared states' do
              it 'can be declared as the value of the name key in the hash' do
                class Foo < Hyperloop::Store
                  class << self
                    state bar: 'a state value', scope: :shared
                  end
                end
                Hyperloop::Application::Boot.run
                foo = Foo.new

                expect(Foo.state.bar).to eq('a state value')
                expect(foo.state.bar).to eq('a state value')
              end

              it 'can be declared with \'initializer: Symbol\'' do
                class Foo < Hyperloop::Store
                  class << self
                    state :bar, scope: :shared, initializer: :baz

                    def baz
                      'a state value'
                    end
                  end
                end
                Hyperloop::Application::Boot.run
                foo = Foo.new

                expect(Foo.state.bar).to eq(Foo.baz)
                expect(foo.state.bar).to eq(Foo.baz)
              end

              it 'can be declared with \'initializer: Proc\'' do
                class Foo < Hyperloop::Store
                  class << self
                    state :bar, scope: :shared, initializer: -> { 'a state value' }
                  end
                end
                Hyperloop::Application::Boot.run
                foo = Foo.new

                expect(Foo.state.bar).to eq('a state value')
                expect(foo.state.bar).to eq('a state value')
              end

              it 'can be declared with a block' do
                class Foo < Hyperloop::Store
                  class << self
                    state :bar, scope: :shared do
                      'a state value'
                    end
                  end
                end
                Hyperloop::Application::Boot.run
                foo = Foo.new

                expect(Foo.state.bar).to eq('a state value')
                expect(foo.state.bar).to eq('a state value')
              end
            end

            context 'for class states' do
              it 'can be declared as the value of the name key in the hash' do
                class Foo < Hyperloop::Store
                  class << self
                    state bar: 'a state value'
                  end
                end
                Hyperloop::Application::Boot.run

                expect(Foo.state.bar).to eq('a state value')
              end

              it 'can be declared with \'initializer: Symbol\'' do
                class Foo < Hyperloop::Store
                  class << self
                    state :bar, initializer: :baz

                    def baz
                      'a state value'
                    end
                  end
                end
                Hyperloop::Application::Boot.run

                expect(Foo.state.bar).to eq(Foo.baz)
              end

              it 'can be declared with \'initializer: Proc\'' do
                class Foo < Hyperloop::Store
                  class << self
                    state :bar, initializer: -> { 'a state value' }
                  end
                end
                Hyperloop::Application::Boot.run

                expect(Foo.state.bar).to eq('a state value')
              end

              it 'can be declared with a block' do
                class Foo < Hyperloop::Store
                  class << self
                    state :bar do
                      'a state value'
                    end
                  end
                end
                Hyperloop::Application::Boot.run

                expect(Foo.state.bar).to eq('a state value')
              end
            end

            context 'for instance states' do
              it 'can be declared as the value of the name key in the hash' do
                class Foo < Hyperloop::Store
                  class << self
                    state bar: 'a state value', scope: :instance
                  end
                end
                foo = Foo.new

                expect(foo.state.bar).to eq('a state value')
              end

              it 'can be declared with \'initializer: Symbol\'' do
                class Foo < Hyperloop::Store
                  class << self
                    state :bar, scope: :instance, initializer: :baz
                  end

                  def baz
                    'a state value'
                  end
                end
                foo = Foo.new

                expect(foo.state.bar).to eq(foo.baz)
              end

              it 'can be declared with \'initializer: Proc\'' do
                class Foo < Hyperloop::Store
                  class << self
                    state :bar, scope: :instance, initializer: -> { 'a state value' }
                  end
                end
                foo = Foo.new

                expect(foo.state.bar).to eq('a state value')
              end

              it 'can be declared with a block' do
                class Foo < Hyperloop::Store
                  class << self
                    state :bar, scope: :instance do
                      'a state value'
                    end
                  end
                end
                foo = Foo.new

                expect(foo.state.bar).to eq('a state value')
              end
            end
          end
        end
      end

      context 'arguments' do
        after(:each) do
          # There's gotta be a better way to deal with this
          Object.send(:remove_const, :Foo)

          # We're very basically mocking React::State so we can run these outside of Opal
          React::State.reset!
        end

        context 'name' do
          it 'can be passed in as a single argument first' do
            class Foo < Hyperloop::Store
              state :bar
            end
            foo = Foo.new
            expect((class << foo.state; self; end).respond_to? :bar).to be_truthy
          end

          it 'can be passed in as a hash argument first' do
            class Foo < Hyperloop::Store
              state bar: nil
            end
            foo = Foo.new
            expect((class << foo.state; self; end).respond_to? :bar).to be_truthy
          end

          it 'will raise an error if it is not passed in first' do
            class Foo < Hyperloop::Store; end

            expect { Foo.state(scope: :class, bar: nil) }
              .to raise_error(HyperStore::StateWrapper::ArgumentValidator::InvalidOptionError)
          end
        end

        context 'reader' do
          context 'declared in the class level' do
            context 'for shared states' do
              it 'will define a reader method of the same name when given \'true\'' do
                class Foo < Hyperloop::Store
                  state :bar, scope: :shared, reader: true
                end
                foo = Foo.new

                expect(foo.methods).to include(:bar)
                expect(Foo.singleton_methods).to include(:bar)
              end

              it 'will define a reader method of the specified when given \'baz\'' do
                class Foo < Hyperloop::Store
                  state :bar, scope: :shared, reader: :baz
                end
                foo = Foo.new

                expect(foo.methods).to_not include(:bar)
                expect(foo.methods).to include(:baz)

                expect(Foo.singleton_methods).to_not include(:bar)
                expect(Foo.singleton_methods).to include(:baz)
              end

              it 'will NOT define a reader method when not passed in' do
                class Foo < Hyperloop::Store
                  state :bar, scope: :shared
                end
                foo = Foo.new

                expect(foo.methods).to_not include(:bar)

                expect(Foo.singleton_methods).to_not include(:bar)
              end
            end

            context 'for class states' do
              it 'will define a reader method of the same name when given \'true\'' do
                class Foo < Hyperloop::Store
                  state :bar, scope: :class, reader: true
                end

                expect(Foo.singleton_methods).to include(:bar)
              end

              it 'will define a reader method of the specified when given \'baz\'' do
                class Foo < Hyperloop::Store
                  state :bar, scope: :class, reader: :baz
                end

                expect(Foo.singleton_methods).to_not include(:bar)
                expect(Foo.singleton_methods).to include(:baz)
              end

              it 'will NOT define a reader method when not passed in' do
                class Foo < Hyperloop::Store
                  state :bar, scope: :class
                end

                expect(Foo.singleton_methods).to_not include(:bar)
              end
            end

            context 'for instance states' do
              it 'will define a reader method of the same name when given \'true\'' do
                class Foo < Hyperloop::Store
                  state :bar, reader: true
                end
                foo = Foo.new

                expect(foo.methods).to include(:bar)
              end

              it 'will define a reader method of the specified when given \'baz\'' do
                class Foo < Hyperloop::Store
                  state :bar, reader: :baz
                end
                foo = Foo.new

                expect(foo.methods).to_not include(:bar)
                expect(foo.methods).to include(:baz)
              end

              it 'will NOT define a reader method when not passed in' do
                class Foo < Hyperloop::Store
                  state :bar
                end
                foo = Foo.new

                expect(foo.methods).to_not include(:bar)
              end
            end
          end

          context 'declared in the singleton class level' do
            context 'for shared states' do
              it 'will define a reader method of the same name when given \'true\'' do
                class Foo < Hyperloop::Store
                  class << self
                    state :bar, scope: :shared, reader: true
                  end
                end
                foo = Foo.new

                expect(foo.methods).to include(:bar)
                expect(Foo.singleton_methods).to include(:bar)
              end

              it 'will define a reader method of the specified when given \'baz\'' do
                class Foo < Hyperloop::Store
                  class << self
                    state :bar, scope: :shared, reader: :baz
                  end
                end
                foo = Foo.new

                expect(foo.methods).to_not include(:bar)
                expect(foo.methods).to include(:baz)

                expect(Foo.singleton_methods).to_not include(:bar)
                expect(Foo.singleton_methods).to include(:baz)
              end

              it 'will NOT define a reader method when not passed in' do
                class Foo < Hyperloop::Store
                  class << self
                    state :bar, scope: :shared
                  end
                end
                foo = Foo.new

                expect(foo.methods).to_not include(:bar)

                expect(Foo.singleton_methods).to_not include(:bar)
              end
            end

            context 'for class states' do
              it 'will define a reader method of the same name when given \'true\'' do
                class Foo < Hyperloop::Store
                  class << self
                    state :bar, reader: true
                  end
                end

                expect(Foo.singleton_methods).to include(:bar)
              end

              it 'will define a reader method of the specified when given \'baz\'' do
                class Foo < Hyperloop::Store
                  class << self
                    state :bar, reader: :baz
                  end
                end

                expect(Foo.singleton_methods).to_not include(:bar)
                expect(Foo.singleton_methods).to include(:baz)
              end

              it 'will NOT define a reader method when not passed in' do
                class Foo < Hyperloop::Store
                  class << self
                    state :bar
                  end
                end

                expect(Foo.singleton_methods).to_not include(:bar)
              end
            end

            context 'for instance states' do
              it 'will define a reader method of the same name when given \'true\'' do
                class Foo < Hyperloop::Store
                  class << self
                    state :bar, scope: :instance, reader: true
                  end
                end
                foo = Foo.new

                expect(foo.methods).to include(:bar)
              end

              it 'will define a reader method of the specified when given \'baz\'' do
                class Foo < Hyperloop::Store
                  class << self
                    state :bar, scope: :instance, reader: :baz
                  end
                end
                foo = Foo.new

                expect(foo.methods).to_not include(:bar)
                expect(foo.methods).to include(:baz)
              end

              it 'will NOT define a reader method when not passed in' do
                class Foo < Hyperloop::Store
                  class << self
                    state :bar, scope: :instance
                  end
                end
                foo = Foo.new

                expect(foo.methods).to_not include(:bar)
              end
            end
          end
        end
      end
    end
  end
end
