require 'spec_helper'

# rubocop:disable Metrics/BlockLength
describe 'the receives macro' do

  before(:all) do
    class TestOp < Hyperloop::Operation
      def self.dispatch(params={})
        receivers.each do |receiver|
          receiver.call params
        end
      end
    end
  end
  after(:each) do
    # There's gotta be a better way to deal with this
    Object.send(:remove_const, :Foo)
    Object.send(:remove_const, :Bar)

    # We're very basically mocking React::State so we can run these outside of Opal
    React::State.reset!
  end

  context 'arguments' do
    before(:each) do
      class Bar < TestOp; end
      class Foo < Hyperloop::Store
        state :bar, scope: :class
      end
    end

    context 'operations' do
      it 'will allow one to be passed in' do
        Foo.class_eval do
          receives Bar do |params|
            mutate.bar(params[:foo])
          end
        end

        expect(Foo.state.bar).to eq(nil)
        Bar.dispatch(foo: 'We dispatched Bar.')
        expect(Foo.state.bar).to eq('We dispatched Bar.')
      end

      it 'will allow several to be passed in' do
        class Baz < TestOp; end
        class Bat < TestOp; end
        Foo.class_eval do
          receives Bar, Baz, Bat do |params|
            mutate.bar(params[:foo])
          end
        end

        expect(Foo.state.bar).to eq(nil)

        Bar.dispatch(foo: 'We dispatched Bar.')
        expect(Foo.state.bar).to eq('We dispatched Bar.')

        Baz.dispatch(foo: 'We dispatched Baz.')
        expect(Foo.state.bar).to eq('We dispatched Baz.')

        Bat.dispatch(foo: 'We dispatched Bat.')
        expect(Foo.state.bar).to eq('We dispatched Bat.')
      end

      it 'will allow one passed in to different receivers' do
        class Baz < TestOp; end
        class Bat < TestOp; end
        Foo.class_eval do
          receives Bar do |params|
            mutate.bar(params[:bar])
          end

          receives Baz do |params|
            mutate.bar(params[:baz])
          end

          receives Bat do |params|
            mutate.bar(params[:bat])
          end
        end

        expect(Foo.state.bar).to eq(nil)

        Bar.dispatch(bar: 'We dispatched Bar.')
        expect(Foo.state.bar).to eq('We dispatched Bar.')

        Baz.dispatch(baz: 'We dispatched Baz.')
        expect(Foo.state.bar).to eq('We dispatched Baz.')

        Bat.dispatch(bat: 'We dispatched Bat.')
        expect(Foo.state.bar).to eq('We dispatched Bat.')
      end

      it 'will allow several passed in to different receivers' do
        class Baz < TestOp; end
        class Bat < TestOp; end
        class Bak < TestOp; end
        class Baq < TestOp; end
        class Bax < TestOp; end
        Foo.class_eval do
          receives Bar, Baz, Bat do |params|
            mutate.bar(params[:foo])
          end

          receives Bak, Baq, Bax do |params|
            mutate.bar(params[:fooz])
          end
        end

        expect(Foo.state.bar).to eq(nil)

        Bar.dispatch(foo: 'We dispatched Bar.')
        expect(Foo.state.bar).to eq('We dispatched Bar.')

        Baz.dispatch(foo: 'We dispatched Baz.')
        expect(Foo.state.bar).to eq('We dispatched Baz.')

        Bat.dispatch(foo: 'We dispatched Bat.')
        expect(Foo.state.bar).to eq('We dispatched Bat.')

        Bak.dispatch(fooz: 'We dispatched Bak.')
        expect(Foo.state.bar).to eq('We dispatched Bak.')

        Baq.dispatch(fooz: 'We dispatched Baq.')
        expect(Foo.state.bar).to eq('We dispatched Baq.')

        Bax.dispatch(fooz: 'We dispatched Bax.')
        expect(Foo.state.bar).to eq('We dispatched Bax.')
      end

      it 'will throw an error if nothing at all is passed in' do
        expect do
          Foo.receives
        end.to raise_error(HyperStore::DispatchReceiver::InvalidOperationError)
      end

      it 'will throw an error if only a Symbol is passed in' do
        Foo.class_eval do
          def self.foo!
            mutate.bar('bar')
          end
        end
        expect do
          Foo.receives :foo!
        end.to raise_error(HyperStore::DispatchReceiver::InvalidOperationError)
      end

      it 'will throw an error if only a Proc is passed in' do
        expect do
          Foo.receives -> { mutate.bar('foo') }
        end.to raise_error(HyperStore::DispatchReceiver::InvalidOperationError)
      end

      it 'will throw an error if only a block is passed in' do
        expect do
          Foo.receives do
            mutate.bar('foo')
          end
        end.to raise_error(HyperStore::DispatchReceiver::InvalidOperationError)
      end
    end

    context 'callback' do
      it 'can be passed in as a Symbol' do
        Foo.class_eval do
          receives Bar, :foo!

          def self.foo!
            mutate.bar('foo')
          end
        end

        expect(Foo.state.bar).to eq(nil)

        Bar.dispatch

        expect(Foo.state.bar).to eq('foo')
      end

      it 'can be passed in as a Proc' do
        Foo.class_eval do
          receives Bar, -> { mutate.bar('foo') }
        end

        expect(Foo.state.bar).to eq(nil)

        Bar.dispatch

        expect(Foo.state.bar).to eq('foo')
      end

      it 'can be passed in as a block' do
        Foo.class_eval do
          receives Bar do
            mutate.bar('foo')
          end
        end

        expect(Foo.state.bar).to eq(nil)

        Bar.dispatch

        expect(Foo.state.bar).to eq('foo')
      end

      it 'will pass in params to the block' do
        Foo.class_eval do
          receives Bar do |params|
            mutate.bar(params[:foo])
          end
        end

        expect(Foo.state.bar).to eq(nil)
        Bar.dispatch(foo: 'I am a param!')
        expect(Foo.state.bar).to eq('I am a param!')
      end

      it 'will can access params inside block without implicitly declaring them' do
        Foo.class_eval do
          receives Bar do
            mutate.bar(params[:foo])
          end
        end

        expect(Foo.state.bar).to eq(nil)
        Bar.dispatch(foo: 'I am a param!')
        expect(Foo.state.bar).to eq('I am a param!')
      end
    end
  end
end
