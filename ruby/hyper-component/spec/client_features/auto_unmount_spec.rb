require 'spec_helper'

describe 'Auto Unmounting', js: true do
  context 'Of timers' do
    before(:each) do
      on_client do
        class Mounter < HyperComponent
          include Hyperstack::State::Observable
          param :keep_running
          class << self
            attr_reader :stayed_running
            def timer_went_off!
              @stayed_running = true
            end
          end
          after_mount do
            after(1) { mutate @state = :cancel_and_wait }
            after(3) { mutate @state = :final_result }
          end
          render do
            puts "rendering with #{@state}"
            case @state
            when :cancel_and_wait
              "waiting..."
            when :final_result
              "works!" if !!Mounter.stayed_running == params.keep_running
            else
              Mounted(keep_running: params.keep_running)
            end
          end
        end
        class Mounted < HyperComponent
          param :keep_running
          after_mount do
            if params.keep_running
              Mounted.after(2) { puts "timer is going off!"; Mounter.timer_went_off! }
            else
              after(2) { puts "timer is going off!"; Mounter.timer_went_off! }
            end
          end
          render do
            "Mounted!"
          end
        end
      end
    end

    it 'automatically unmounts timers' do
      mount 'Mounter', keep_running: false
      expect(page).to have_content("works!")
    end
    it 'unless using the classes timer' do
      mount 'Mounter', keep_running: true
      expect(page).to have_content("works!")
    end
  end

  it "automatically will unmount observable objects" do
    mount 'Mounter' do
      class ObservableObject
        include Hyperstack::State::Observable
        state_reader :state
        def initialize
          @state = :mounted
          after(0) { mutate @state = :waiting_to_unmount }
        end
        before_unmount { mutate @state = :unmounted }
      end
      class Mounter < HyperComponent
        include Hyperstack::State::Observable
        before_mount { @observable_object = ObservableObject.new }
        render do
          puts "rendering with #{@observable_object.state}"
          case @observable_object.state
          when :mounted
            Mounted(observable_object: @observable_object)
          when :waiting_to_unmount
            "waiting to unmount"
          when :unmounted
            "unmounted"
          end
        end
      end
      class Mounted < HyperComponent
        param :observable_object
        before_mount do
          @observable_object = params.observable_object
        end
        render do
          "Mounted!"
        end
      end
    end
    expect(page).to have_content("unmounted")
  end
end
