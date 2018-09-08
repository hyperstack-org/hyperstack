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
                    H1 { "@foo.state.bar: #{@foo.state.bar}" }
                  end
                end
              end

              expect(page).to have_content('@foo.state.bar: ')
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
    end
  end
end
