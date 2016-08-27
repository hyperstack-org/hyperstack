require 'spec_helper'

class Test

  def self.capture_block(&block)
    blocks << block
  end

  def self.blocks
    @blocks ||= []
  end

end

class Test2

  def baz
    'baz'
  end

end

describe 'ruby' do

  it 'can set self to something else for a block' do

    Test.capture_block do |pow|
      "#{baz}-#{pow}"
    end

    Test2.new.instance_exec("hoho", &Test.blocks.first).should eq("baz-hoho")
  end
end
