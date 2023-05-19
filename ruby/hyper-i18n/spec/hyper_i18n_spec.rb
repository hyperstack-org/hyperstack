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
            DIV(id: :tp7) { t(:hello) }
            DIV(id: :tp8) { t(:hello_world) }
            DIV(id: :tp9) { t(:that_other_key) }
          end
        end
      end
    end
  end

  [['component rendering', :client_only], ['prerendering', :server_only]].each do |mode, flag|
    it "will translate during #{mode}", prerendering_on: flag == :server_only do
      mount 'Components::TestComponent', {}, render_on: flag
      expect(find('#tp1')).to have_content('I am a key')
      expect(find('#tp2')).to have_content('Hello world')
      expect(find('#tp3')).to have_content(::I18n.l(Time.parse('1/1/2018 12:45')))
      expect(find('#tp4')).to have_content(::I18n.l(Time.parse('1/1/2018 12:45'), format: '%B %d, %Y at %l:%M %P'))
      expect(find('#tp5')).to have_content('My Model')
      expect(find('#tp6')).to have_content('The Attribute')
      expect(find('#tp7')).to have_content('Hello world')
      expect(find('#tp8')).to have_content('Hello World')
      expect(find('#tp9')).to have_content('I am another key')
    end
  end
end
