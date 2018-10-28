require 'spec_helper'

describe Hyperstack::Internal::AutoUnmount do
  before(:each) do
    base_class = Class.new
    base_class.class_eval do
      def every
        every_called
      end

      def after
        after_called
      end
    end
    application_class = Class.new(base_class)
    application_class.include subject
    @async_obj = application_class.new
  end

  %i[every after].each do |meth|
    it "will pass through calls to #{meth} to the super class when mounted, and abort calls to the #{meth} method when unmounting" do
      timer = double('timer')
      expect(@async_obj).to receive(:"#{meth}_called").and_return(timer)
      @async_obj.send(meth)
      expect(timer).to receive(:abort)
      @async_obj.unmount
    end

    it "will ignore calls to the #{meth} method once unmounted" do
      @async_obj.unmount
      expect(@async_obj).not_to receive(:"#{meth}_called")
      expect(@async_obj.send(meth)).to be_nil
    end
  end

  it 'will receive from and close broadcast channels with the receives method' do
    broadcaster = double('Broadcaster')
    expect(broadcaster).to receive(:receiver).with(@async_obj).and_return(broadcaster)
    @async_obj.receives(broadcaster)
    expect(broadcaster).to receive(:unmount)
    @async_obj.unmount
  end

  it "will ignore calls to the receives method once unmounted" do
    broadcaster = double('Broadcaster')
    @async_obj.unmount
    expect(@async_obj).not_to receive(:receiver)
    expect(@async_obj.receives(broadcaster)).to be_nil
  end

  it 'will unmount objects referenced by instance variables' do
    unmountable_object = double('unmountable_object')
    regular_object = double('regular_object')
    @async_obj.instance_variable_set(:@unmountable_object, unmountable_object)
    @async_obj.instance_variable_set(:@regular_object, regular_object)
    expect(unmountable_object).to receive(:unmount)
    @async_obj.unmount
  end
end
