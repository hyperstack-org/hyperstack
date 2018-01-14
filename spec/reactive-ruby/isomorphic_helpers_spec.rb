require 'spec_helper'

describe React::IsomorphicHelpers do
  describe 'code execution context' do
    let(:klass) { Class.send(:include, described_class) }

    describe 'module class methods', :opal do
      it { expect(described_class).to_not be_on_opal_server }
      it { expect(described_class).to be_on_opal_client }
    end

    describe 'included class methods', :opal do
      it { expect(klass).to_not be_on_opal_server }
      it { expect(klass).to be_on_opal_client }
    end

    describe 'included instance methods', :opal do
      it { expect(klass.new).to_not be_on_opal_server }
      it { expect(klass.new).to be_on_opal_client }
    end

    describe 'module class methods', :ruby do
      it { is_expected.to_not be_on_opal_server }
      it { is_expected.to_not be_on_opal_client }
    end

    describe 'included class methods', :ruby do
      subject { klass }
      it { is_expected.to_not be_on_opal_server }
      it { is_expected.to_not be_on_opal_client }
    end

    describe 'included instance methods', :ruby do
      subject { klass.new }
      it { is_expected.to_not be_on_opal_server }
      it { is_expected.to_not be_on_opal_client }
    end
  end

  describe 'load_context', :ruby do
    let(:v8_context) { TestV8Context.new }
    let(:controller) { double('controller') }
    let(:name) { double('name') }

    it 'creates a context and sets a controller' do
      context = described_class.load_context(v8_context, controller, name)
      expect(context.controller).to eq(controller)
    end

    it 'creates a context and sets a unique_id', js: true do
      # this tests loads the prerender context and somehow trys evaluate_ruby, works only with above js: true
      # TODO this is triggered by TimeCop for some reason
      Timecop.freeze do
        stamp = Time.now.to_i
        context = described_class.load_context(v8_context, controller, name)
        expect(context.unique_id).to eq("#{ controller.object_id }-#{ stamp }")
      end
    end
  end

  describe React::IsomorphicHelpers::Context do
    class TestV8Context < Hash
      def eval(args)
        true
      end
      def attach(*args)
        true
      end
    end

    # Need to decouple/dry up this...
    def test_context(files = nil)
      js = ReactiveRuby::ServerRendering::ContextualRenderer::CONSOLE_POLYFILL.dup
      js << Opal::Builder.build('opal').to_s
      Array(files).each do |filename|
        js << ::Rails.application.assets[filename].to_s
      end
      js = "#{React::ServerRendering::ExecJSRenderer::GLOBAL_WRAPPER}#{js}"
      ctx = ExecJS.compile(js)
      ctx = ReactiveRuby::ServerRendering.context_instance_for(ctx)
    end

    def react_context
      if ::Rails.application.assets['react-server.js']
        test_context(['server_rendering.js', 'react-server.js'])
      else
        test_context(['components', 'react.js'])
      end
    end

    let(:v8_context) { TestV8Context.new }
    let(:controller) { double('controller') }
    let(:name) { double('name') }
    before do
      described_class.instance_variable_set :@before_first_mount_blocks, nil
    end

    describe '#initialize' do
      it 'calls before mount callbacks' do
        string = instance_double(String)
        described_class.register_before_first_mount_block do
          string.inspect
        end
        expect(string).to receive(:inspect).once
        context = described_class.new('unique-id', v8_context, controller, name)
      end
    end

    describe '#eval' do
      it 'delegates to given context' do
        context = described_class.new('unique-id', v8_context, controller, name)
        js = 'true;'
        expect(v8_context).to receive(:eval).with(js).once
        context.eval(js)
      end
    end

    describe '#send_to_opal' do
      let(:opal_code) { Opal::Builder.new.build_str(ruby_code, __FILE__).to_s }
      let(:ruby_code) { %Q[
        module React::IsomorphicHelpers
          def self.greet(name)
            "Hello, " + name + "!"
          end

          def self.valediction
            'Goodbye'
          end
        end
      ]}

      it 'raises an error when react cannot be loaded' do
        context = described_class.new('unique-id', v8_context, controller, name)
        context.instance_variable_set(:@ctx, test_context)
        expect {
          context.send_to_opal(:foo)
        }.to raise_error(/No HyperReact components found/)
      end

      it 'executes method with args inside opal rubyracer context' do
        ctx = react_context
        context = described_class.new('unique-id', ctx, controller, name)
        context.eval(opal_code)
        result = context.send_to_opal(:greet, 'world')
        expect(result).to eq('Hello, world!')
      end

      it 'executes the method inside opal rubyracer context' do
        ctx = react_context
        context = described_class.new('unique-id', ctx, controller, name)
        context.eval(opal_code)
        result = context.send_to_opal(:valediction)
        expect(result).to eq('Goodbye')
      end
    end
  end
end
