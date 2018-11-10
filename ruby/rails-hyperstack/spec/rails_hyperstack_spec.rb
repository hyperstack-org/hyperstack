require 'spec_helper'

describe 'rails-hyperstack' do
  it 'builds a working app', js: true do
    visit '/'
    expect(page).to have_content('App')
  end
  it 'installs hyper-model and friends', js: true do
    visit '/'
    expect_promise do
      Hyperstack::Model.load { Sample.count }
    end.to eq(0)
    evaluate_ruby do
      Sample.create(name: 'sample1', description: 'the first sample')
    end
    wait_for_ajax
    expect(Sample.count).to eq(1)
    expect(Sample.first.name).to eq('sample1')
    expect(Sample.first.description).to eq('the first sample')
    expect_evaluate_ruby do
      Sample.count
    end.to eq(1)
  end
end
