require 'spec_helper'

describe 'Home Page Examples', js: true do
  it 'says hello' do
    mount 'HelloWorld'
    expect(page).to have_content('Hello world')
    expect(page).to have_content("Let's gets started!")
  end
  it 'displaysthe HTML DSL Example' do
    mount 'HtmlDslExample'
    the_div = find('h3', text: 'Blue Box').find(:xpath, "..")
    expect(the_div.tag_name).to eq('div')
    expect(the_div[:class].split).to match_array("ui info message".split)
    the_table = find('table')
    expect(the_table[:class].split).to match_array("ui celled table".split)
    %w[One Two Three].each do |text|
      th = find('th', text: text)
      expect(th.find(:xpath, '..').tag_name).to eq('tr')
      expect(th.find(:xpath, '../..').tag_name).to eq('thead')
      expect(th.find(:xpath, '../../..')).to eq(the_table)
    end
    { 'A' => '', 'B' => 'negative', 'C' => '' }.each do |text, classes|
      td = find('td', text: text)
      expect(td[:class]).to eq(classes)
      expect(td.find(:xpath, '..').tag_name).to eq('tr')
      expect(td.find(:xpath, '../..').tag_name).to eq('tbody')
      expect(td.find(:xpath, '../../..')).to eq(the_table)
    end
    10.times do |n|
      li = find('li', text: "Number #{n}")
      expect(li.find(:xpath, '..').tag_name).to eq('ul')
    end
  end
end
