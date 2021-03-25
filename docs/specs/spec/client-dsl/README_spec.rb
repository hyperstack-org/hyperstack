require 'spec_helper'
describe "README", :js do
  it "Clock" do
    mount "Clock" do
      class Clock < HyperComponent
        # Components can be parameterized.
        # in this case you can override the default
        # with a different format
        param format: "%d-%m-%Y %I:%M:%S %p"
        # before_mount and after_mount are examples of a life cycle methods.
        before_mount do
          # Before the component is first rendered (mounted)
          # we initialize @current_time
          @current_time = Time.now
        end
        after_mount do
          # after the component is mounted
          # we setup a periodic timer that will update the
          # current_time instance variable every second.
          # The mutate method signals a change in state
          every(1.second) { mutate @current_time = Time.now }
        end
        # every component has a render block which describes what will be
        # drawn on the UI
        render do
          # Components can render other components or primitive HTML or SVG
          # tags.  Components also use their state to determine what to render,
          # in this case the @current_time instance variable
          DIV { @current_time.strftime(format) }
        end
      end
    end
    expect(Time.parse(find("div div").text)).to be_within(5.seconds).of Time.now
    Timecop.travel(Time.now+30.seconds) do
      sleep 1
      expect(Time.parse(find("div div").text)).to be_within(5.seconds).of Time.now
    end
  end
end
