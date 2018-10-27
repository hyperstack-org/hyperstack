require 'spec_helper'

# rubocop:disable Metrics/BlockLength
describe 'HyperComponent Integration', js: true do
  it "Hyper-components will update when their internal instance state is mutated" do
    mount "TestComp" do
      class TestComp
        include Hyperstack::Component
        include Hyperstack::State::Observable
        before_mount do
          @click_count = 0
          @render_count = 0
        end
        render(DIV) do
          @render_count += 1
          DIV { "I have been clicked #{@click_count} times. I have been rendered #{@render_count} times." }
          BUTTON(id: :click_me) { "CLICK ME" }
          .on(:click) { mutate @click_count += 1 }
        end
      end
    end
    expect(page).to have_content('I have been clicked 0 times. I have been rendered 1 times.')
    page.find('#click_me').click
    expect(page).to have_content('I have been clicked 1 times. I have been rendered 2 times.')
  end

  it "Only the component being mutated will update" do
    mount "TestComp" do
      class TestComp
        include Hyperstack::Component
        before_mount { @render_count = 0 }
        render(DIV) do
          @render_count += 1
          DIV { "Test Comp rendered #{@render_count} times."}
          2.times { |i| StateTest(id: i) }
        end
      end
      class StateTest
        include Hyperstack::Component
        include Hyperstack::State::Observable

        param :id

        state_writer :click_count

        def click_count
          @click_count ||= 0
        end

        before_mount do
          @render_count = 0
        end

        render(DIV) do
          @render_count += 1
          DIV { "click_count = #{click_count}. StateTest(id: #{params.id}) rendered #{@render_count} times." }
          BUTTON(id: "click_me_#{params.id}") { "CLICK ME" }
          .on(:click) { self.click_count += 1 }
        end
      end
    end
    expect(page).to have_content('click_count = 0. StateTest(id: 0) rendered 1 times.')
    expect(page).to have_content('click_count = 0. StateTest(id: 1) rendered 1 times.')
    page.find('#click_me_0').click
    expect(page).to have_content('click_count = 1. StateTest(id: 0) rendered 2 times.')
    expect(page).to have_content('click_count = 0. StateTest(id: 1) rendered 1 times.')
    page.find('#click_me_1').click
    expect(page).to have_content('click_count = 1. StateTest(id: 0) rendered 2 times.')
    expect(page).to have_content('click_count = 1. StateTest(id: 1) rendered 2 times.')
  end

  it "Hyper-components will update when their internal class state is mutated" do
    mount "TestComp" do
      class TestComp
        include Hyperstack::Component
        before_mount { @render_count = 0 }
        render(DIV) do
          @render_count += 1
          DIV { "Test Comp rendered #{@render_count} times."}
          2.times { |i| StateTest(id: i) }
        end
      end
      class StateTest
        include Hyperstack::Component
        include Hyperstack::State::Observable

        param :id

        class << self
          state_writer :click_count
          def click_count
            @click_count ||= 0
          end
        end

        before_mount do
          @render_count = 0
        end

        render(DIV) do
          @render_count += 1
          DIV { "StateTest.count = #{StateTest.click_count}. StateTest(id: #{params.id}) rendered #{@render_count} times." }
          BUTTON(id: "click_me_#{params.id}") { "CLICK ME" }
          .on(:click) { StateTest.click_count += 1 }
        end
      end
    end
    expect(page).to have_content('StateTest.count = 0. StateTest(id: 0) rendered 1 times.')
    expect(page).to have_content('StateTest.count = 0. StateTest(id: 1) rendered 1 times.')
    page.find('#click_me_0').click
    expect(page).to have_content('StateTest.count = 1. StateTest(id: 0) rendered 2 times.')
    expect(page).to have_content('StateTest.count = 1. StateTest(id: 1) rendered 2 times.')
    page.find('#click_me_1').click
    expect(page).to have_content('StateTest.count = 2. StateTest(id: 0) rendered 3 times.')
    expect(page).to have_content('StateTest.count = 2. StateTest(id: 1) rendered 3 times.')
  end

  it "Hyper-components will update when an external state is mutated" do
    mount "TestComp" do
      class Store
        include Hyperstack::State::Observable
        class << self
          state_writer :count
          observer :count do
            @count ||= 0
          end
        end
      end
      class TestComp
        include Hyperstack::Component
        before_mount do
          @render_count = 0
        end
        render(DIV) do
          @render_count += 1
          DIV { "I have been clicked #{Store.count} times. I have been rendered #{@render_count} times." }
          BUTTON(id: :click_me) { "CLICK ME" }
          .on(:click) { Store.count += 1 }
        end
      end
    end
    expect(page).to have_content('I have been clicked 0 times. I have been rendered 1 times.')
    page.find('#click_me').click
    expect(page).to have_content('I have been clicked 1 times. I have been rendered 2 times.')
  end
end
