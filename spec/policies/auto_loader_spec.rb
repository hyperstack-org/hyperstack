
require 'spec_helper'

describe 'rails autoloader' do

  # can't figure out how to get rails to dump class cache between tests so
  # we define two different class policy pairs...

  context "when using const_set" do

    it 'will find the policy class file if available' do
      stub_const "AutoLoaderTestClassa", Class.new
      expect(Hyperloop::AutoConnect.channels(0, nil)).to eq(["AutoLoaderTestClassa"])
    end

    it 'will raise a load error if file does not define the class' do
      expect { stub_const "AutoLoaderTestClassc", Class.new }.to raise_error(LoadError)
    end
  end

  context "when defining a new class" do

    it 'will find the policy class if available' do
      class AutoLoaderTestClassb
      end
      expect(Hyperloop::AutoConnect.channels(0, nil)).to eq(["AutoLoaderTestClassb"])
    end

    it 'will raise a load error if file does not define the class' do
      expect { class AutoLoaderTestClassd; end }.to raise_error(LoadError)
    end
  end

end
