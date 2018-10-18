require 'spec_helper'

def class_of(x)
  (class << x; self end)
end

# Just checks to make sure all methods are available when either subclassing or including
describe 'subclassing HyperStore' do
  before(:each) do
    class Foo < HyperStore
    end
  end

  context 'singleton_level' do
    it 'should define the :state macro' do
      expect(Foo.singleton_class.singleton_methods).to include(:state)
    end
  end

  context 'class level' do
    it 'should define the :state method' do
      expect(Foo.singleton_methods).to include(:state)
      expect(class_of(Foo.state)).to be < HyperStore::StateWrapper
    end

    it 'should define the :mutate method' do
      expect(Foo.singleton_methods).to include(:mutate)
      expect(class_of(Foo.mutate)).to be < HyperStore::MutatorWrapper
    end

    it 'should define the :receieves method' do
      expect(Foo.singleton_methods).to include(:receives)
    end
  end

  context 'instance level' do
    before(:each) { @foo = Foo.new }

    it 'should define the :state method' do
      expect(@foo.methods).to include(:state)
      expect(class_of(@foo.state)).to be < HyperStore::StateWrapper
    end

    it 'should define the :mutate method' do
      expect(@foo.methods).to include(:mutate)
      expect(class_of(@foo.mutate)).to be < HyperStore::MutatorWrapper
    end
  end
end

describe 'including HyperStore::Mixin' do
  before(:each) do
    class Foo
      include HyperStore::Mixin
    end
  end

  context 'singleton_level' do
    it 'should define the :state macro' do
      expect(Foo.singleton_class.singleton_methods).to include(:state)
    end
  end

  context 'class level' do
    it 'should define the :state method' do
      expect(Foo.singleton_methods).to include(:state)
      expect(class_of(Foo.state)).to be < HyperStore::StateWrapper
    end

    it 'should define the :mutate method' do
      expect(Foo.singleton_methods).to include(:mutate)
      expect(class_of(Foo.mutate)).to be < HyperStore::MutatorWrapper
    end

    it 'should define the :receieves method' do
      expect(Foo.singleton_methods).to include(:receives)
    end
  end

  context 'instance level' do
    before(:each) { @foo = Foo.new }

    it 'should define the :state method' do
      expect(@foo.methods).to include(:state)
      expect(class_of(@foo.state)).to be < HyperStore::StateWrapper
    end

    it 'should define the :mutate method' do
      expect(@foo.methods).to include(:mutate)
      expect(class_of(@foo.mutate)).to be < HyperStore::MutatorWrapper
    end
  end
end
