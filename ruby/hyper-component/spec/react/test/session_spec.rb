require 'spec_helper'

if RUBY_ENGINE == 'opal' 
  RSpec.describe React::Test::Session do
    subject { described_class.new }
    before do
      stub_const 'Greeter', Class.new
      Greeter.class_eval do
        include React::Component

        params do
          optional :message
          optional :from
        end

        def render
          span { "Hello #{params.message}" }
        end
      end
    end

    describe '#mount' do
      it 'returns an instance of the mounted component' do
        expect(subject.mount(Greeter)).to be_a(Greeter)
      end

      it 'actualy mounts the component' do
        expect(subject.mount(Greeter)).to be_mounted
      end

      it 'optionaly passes params to the component' do
        instance = subject.mount(Greeter, message: 'world')
        expect(instance.params.message).to eq('world')
      end
    end

    describe '#instance' do
      it 'returns the instance of the mounted component' do
        instance = subject.mount(Greeter)
        expect(subject.instance).to eq(instance)
      end
    end

    describe '#html' do
      it 'returns the component rendered to static html' do
        subject.mount(Greeter, message: 'world')
        expect(subject.html).to eq('<span>Hello world</span>')
      end

      async 'returns the updated static html' do
        subject.mount(Greeter)
        subject.update_params(message: 'moon') do
          run_async {
            expect(subject.html).to eq('<span>Hello moon</span>')
          }
        end
      end
    end

    describe '#update_params' do
      it 'sends new params to the component' do
        instance = subject.mount(Greeter, message: 'world')
        subject.update_params(message: 'moon')
        expect(instance.params.message).to eq('moon')
      end

      it 'leaves unspecified params in tact' do
        instance = subject.mount(Greeter, message: 'world', from: 'outerspace')
        subject.update_params(message: 'moon')
        expect(instance.params.from).to eq('outerspace')
      end

      it 'causes the component to render' do
        instance = subject.mount(Greeter, message: 'world')
        expect(instance).to receive(:render)
        subject.update_params(message: 'moon')
      end
    end

    describe 'instance#force_update!' do
      it 'causes the component to render' do
        instance = subject.mount(Greeter)
        expect(instance).to receive(:render)
        subject.instance.force_update!
      end
    end
  end
end
