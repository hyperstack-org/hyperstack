require 'spec_helper'

describe "Hyperstack::Router", js: true do

  it "can route" do
    visit '/'
    page.find('a', id: 'about_link').click
    expect(page).to have_content('About Page')
    expect(page.current_path).to eq('/about')
    page.find('a', id: 'topics_link').click
    expect(page).to have_content('Topics Page')
    expect(page.current_path).to eq('/topics')
    page.find('a', id: 'components_link').click
    expect(page).to have_content('more on components...')
    expect(page.current_path).to eq('/topics/components')
  end
end
