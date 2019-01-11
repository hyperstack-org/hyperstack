require 'spec_helper'

describe 'misc client helpers', js: true do
  context 'pluralize' do
    before(:each) do
      on_client do
        class TestComponent < Hyperloop::Component
          param :count
          render(DIV) do
            DIV { pluralize(@Count, "criterium") }
            DIV { pluralize(@Count, "item", "itemz") }
          end
        end
      end
    end
    it "1 will be singlular" do
      mount 'TestComponent', count: 1
      expect(page).to have_content("1 criterium")
      expect(page).to have_content("1 item")
    end
    it "2 will be plural" do
      mount 'TestComponent', count: 2
      expect(page).to have_content("2 criteria")
      expect(page).to have_content("2 itemz")
    end
  end
end
