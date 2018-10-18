require 'spec_helper'

describe Hyperstack::Component::Internal::Rails::ComponentLoader do
  GLOBAL_WRAPPER = <<-JS
    #{React::ServerRendering::ExecJSRenderer::GLOBAL_WRAPPER}
    var console = {
      warn: function(s) {  }
    };
  JS

  let(:js) do
    if ::Rails.application.assets['react-server.js']
      react_source = ::Rails.application.assets['react-server.js']
    else
      react_source = ::Rails.application.assets['react.js']
    end
    ::Rails.application.assets['components'].to_s + react_source.to_s
  end
  let(:context) { ExecJS.compile(GLOBAL_WRAPPER + js) }
  let(:v8_context) { ReactiveRuby::ServerRendering.context_instance_for(context) }

  describe '.new' do
    it 'raises a meaningful exception when initialized without a context' do
      expect {
        described_class.new(nil)
      }.to raise_error(/Could not obtain ExecJS runtime context/)
    end
  end

  describe '#load' do
    it 'loads given asset file into context', skip: 'feature not implemented yet' do
      loader = described_class.new(v8_context)

      expect {
        loader.load('components')
      }.to change { !!v8_context.eval('Opal.React !== undefined') }.from(false).to(true)
    end

    it 'is truthy upon successful load', skip: 'feature not implemented yet' do
      loader = described_class.new(v8_context)
      expect(loader.load('components')).to be_truthy
    end

    it 'fails silently returning false', skip: 'feature not implemented yet' do
      loader = described_class.new(v8_context)
      expect(loader.load('foo')).to be_falsey
    end
  end

  describe '#load!' do
    it 'is truthy upon successful load', skip: 'feature not implemented yet' do
      loader = described_class.new(v8_context)
      expect(loader.load!('components')).to be_truthy
    end

    it 'raises an expection if loading fails', skip: 'feature not implemented yet' do
      loader = described_class.new(v8_context)
      expect { loader.load!('foo') }.to raise_error(/No HyperReact components/)
    end
  end

  describe '#loaded?' do
    it 'is truthy if components file is already loaded', skip: 'feature not implemented yet' do
      loader = described_class.new(v8_context)
      loader.load('components')
      expect(loader).to be_loaded
    end

    it 'is false if components file is not loaded', skip: 'feature not implemented yet' do
      loader = described_class.new(v8_context)
      expect(loader).to_not be_loaded
    end
  end
end
