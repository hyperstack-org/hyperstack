require 'spec_helper'

describe 'I18n client methods', js: true do
  before(:each) do
    on_client do
      class MyModel < ActiveRecord::Base
      end
      module Components
        class TestComponent
          include Hyperstack::Component
          include Hyperstack::I18n
          render(DIV) do
            DIV(id: :tp1) { t(:the_key) }
            DIV(id: :tp2) { I18n.t(:hello) }
            DIV(id: :tp3) { l(Time.parse('1/1/2018 12:45')) }
            DIV(id: :tp4) { l(Time.parse('1/1/2018 12:45'), '%B %d, %Y at %l:%M %P') }
            DIV(id: :tp5) { MyModel.model_name.human }
            DIV(id: :tp6) { MyModel.human_attribute_name('the_attribute') }
          end
        end
      end
    end
  end
  [['component rendering', :client_only], ['prerendering', :server_only]].each do |mode, flag|
    it "will translate during #{mode}" do
      mount 'Components::TestComponent', {}, render_on: flag
      expect(find('#tp1')).to have_content('I am a key')
      expect(find('#tp2')).to have_content('Hello world')
      expect(find('#tp3')).to have_content('Mon, 01 Jan 2018 12:45:00')
      expect(find('#tp4')).to have_content('January 01, 2018 at 12:45 pm')
      expect(find('#tp5')).to have_content('My Model')
      expect(find('#tp6')).to have_content('The Attribute')
    end
  end
end
