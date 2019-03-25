require 'spec_helper'

describe 'hyper-spec', js: true do
  it 'will mount a component' do
    mount "SayHello", name: 'Fred'
    expect(page).to have_content('Hello there Fred')
  end

  it "can the mount a component defined in mounts code block" do
    mount 'ShowOff' do
      class ShowOff
        include Hyperstack::Component
        render(DIV) { 'Now how cool is that???' }
      end
    end
    expect(page).to have_content('Now how cool is that???')
  end

  context "the client_option method" do

    it "can rendered server side only" do
      client_option render_on: :server_only
      mount 'SayHello', name: 'George'
      expect(page).to have_content('Hello there George')
      expect(evaluate_script('typeof React')).to eq('undefined')
    end

    it "can use the application's layout" do
      client_option layout: 'application'
      mount 'SayHello', name: 'Sam'
      expect(page).to have_content('Hello there Sam')
      expect(evaluate_script('document.title')).to eq('HyperMesh Test App')
    end

    it "can use an alternative style sheet" do
      client_option style_sheet: 'test'
      mount 'StyledDiv' do # see test_app/spec/assets/stylesheets
        class StyledDiv
          include Hyperstack::Component
          render(DIV, id: 'hello', class: 'application-style') do
            'Hello!'
          end
        end
      end
      expect(computed_style('#hello', 'border-right-style')).to eq('solid')
    end

    it "can use an alternative js file" do
      client_option javascript: 'factorial' # see test_app/spec/assets/javascripts
      expect_evaluate_ruby("factorial(5)").to eq(120)
    end
  end

  it "can insert code using the on_client method" do
    on_client do
      SOME_CONSTANT = 12
    end
    expect_evaluate_ruby do
      SOME_CONSTANT
    end.to eq(12)
  end

  it "can load isomorphic code using the isomorphic method" do
    isomorphic do
      def factorial(n)
        n==1 ? 1 : n * factorial(n-1)
      end
    end
    expect(evaluate_ruby('factorial(5)')).to eq(factorial(5))
  end

  context 'promise helpers' do
    # just to demonstrate a few things:
    # 1 - You can use methods like mount, isomorphic, on_client in before(:each) blocks
    # 2 - Its not hurting anything to define "wait" isomorphically since it will never be called on the server
    before(:each) do
      isomorphic do
        DELAY = 2 unless defined? DELAY
        def wait(seconds)
          Promise.new.tap { |p| after(seconds) { p.resolve(seconds) }}
        end
      end
    end

    it 'evaluate_promise will wait for the promise to resolve' do
      start = Time.now
      answer =
      evaluate_promise do
        wait(DELAY)
      end
      expect(answer).to eq(DELAY)
      expect(Time.now-start).to be >= DELAY
    end

    it 'expect_promise will wait for the promise to resolve' do
      start = Time.now
      expect_promise do
        wait(DELAY)
      end.to eq(DELAY)
      expect(Time.now-start).to be >= DELAY
    end
  end

  context 'event and callback handlers' do

    before(:each) do
      mount 'CallBackOnEveryThirdClick' do
        class CallBackOnEveryThirdClick
          include Hyperstack::Component
          include Hyperstack::State::Observable
          param :click3, type: Proc
          triggers :click3
          before_mount { @clicks = 0 }
          def increment_click
            mutate @clicks += 1
            if @clicks % 3 == 0
              @Click3.call(@clicks)
              click3!(@clicks)
            end
          end
          render do
            DIV do
              SPAN { "I have been clicked #{@clicks} times" }
              BUTTON(class: :tp_clicker) { "click me again" }
              .on(:click) { increment_click }
            end
          end
        end
      end
    end

    it "will record the callback_history" do
      7.times { find(".tp_clicker").click }
      expect(callback_history_for(:click3)).to eq([[3], [6]])
      expect(last_callback_for(:click3)).to eq([6])
      clear_callback_history_for(:click3)
      expect(last_callback_for(:click3)).to eq(nil)
      2.times { find(".tp_clicker").click }
      expect(callback_history_for(:click3)).to eq([[9]])
      expect(last_callback_for(:click3)).to eq([9])
    end

    it "will record the event_history" do
      7.times { find(".tp_clicker").click }
      expect(event_history_for(:click3)).to eq([[3], [6]])
      expect(last_event_for(:click3)).to eq([6])
      clear_event_history_for(:click3)
      expect(last_event_for(:click3)).to eq(nil)
      2.times { find(".tp_clicker").click }
      expect(event_history_for(:click3)).to eq([[9]])
      expect(last_event_for(:click3)).to eq([9])
    end

  end

  it "can add classes during testing" do
    add_class :some_class, borderStyle: :solid
    mount 'StyledDiv' do
      class StyledDiv
        include Hyperstack::Component
        render(DIV, id: 'hello', class: 'some_class') do
          'Hello!'
        end
      end
    end
    expect(computed_style('#hello', 'border-right-style')).to eq('solid')
  end

  context "TimeCop integration" do

    # javascript time does not always advance until you do some I/O so
    # we prefix all Time.now.to_i with a `puts ''`

    before(:each) do
      @sync_gap = Time.now.to_i - evaluate_ruby('Time.now.to_i')
    end

    it "will use TimeCop frozen time" do
      Timecop.freeze Time.now-1.year do
        expect(evaluate_ruby('Time.now.to_i')).to eq(Time.now.to_i)
      end
      expect(evaluate_ruby('puts ""; Time.now.to_i')).to be_within(1).of(Time.now.to_i)
    end

    it "will use TimeCop travelling time" do

      Timecop.travel Time.now-1.year do
        expect(evaluate_ruby('puts ""; Time.now.to_i')).to be_within(1).of(Time.now.to_i)
        sleep 3
        expect(evaluate_ruby('puts ""; Time.now.to_i')).to be_within(1).of(Time.now.to_i)
      end

      expect(evaluate_ruby('puts ""; Time.now.to_i')).to be_within(1).of(Time.now.to_i+@sync_gap)
    end

    it "will use TimeCop travelling time with scaling" do
      Timecop.scale 60, Time.now-1.year do
        expect(evaluate_ruby('puts ""; Time.now.to_i')).to be_within(2).of(Time.now.to_i)
        start_time = Time.now
        sleep 1 # sleep is still in "real time" but Time will move 60 times faster
        expect(start_time).to be_within(1).of(Time.now-1.minute)
        expect(evaluate_ruby('puts ""; Time.now.to_i')).to be_within(2).of(Time.now.to_i)
      end
      expect(evaluate_ruby('Time.now.to_i')).to be_within(2).of(Time.now.to_i+@sync_gap)
    end

    it "will advance time along with time cop freezing" do
      Timecop.freeze Time.now+1.year
      expect(evaluate_ruby('puts ""; Time.now.to_i')).to be_within(1).of(Time.now.to_i)
      Timecop.freeze Time.now-2.years
      expect(evaluate_ruby('puts ""; Time.now.to_i')).to be_within(1).of(Time.now.to_i)
      Timecop.return
      expect(evaluate_ruby('puts ""; Time.now.to_i')).to be_within(2).of(Time.now.to_i+@sync_gap)
    end

    it "can temporarily return to true time" do
      Timecop.freeze Time.now+1.year do
        expect(evaluate_ruby('puts ""; Time.now.to_i')).to be_within(1).of(Time.now.to_i)
        Timecop.return do
          expect(evaluate_ruby('puts ""; Time.now.to_i')).to be_within(1).of(Time.now.to_i)
        end
      end
      expect(evaluate_ruby('puts ""; Time.now.to_i')).to be_within(1).of(Time.now.to_i+@sync_gap)
    end
  end
end

RSpec::Steps.steps "will size_window to", js: true do

  before(:step) do
    calculate_window_restrictions
  end

  it "the default size" do
    size_window
    expect(dims).to eq(adjusted(1024, 768))
  end

  it "the default portrait size" do
    size_window(:portrait)
    expect(dims).to eq(adjusted(768, 1024))
  end

  it ":small" do
    size_window(:small)
    expect(dims).to eq(adjusted(480, 320))
  end

  it ":mobile" do
    size_window(:mobile)
    expect(dims).to eq(adjusted(640, 480))
  end

  it ":tablet" do
    size_window(:tablet)
    expect(dims).to eq(adjusted(960, 640))
  end

  it ":large" do
    size_window(:large)
    expect(dims).to eq(adjusted(1920, 6000))
  end

  it ":portrait (as first arg)" do
    size_window(:portrait, :mobile)
    expect(dims).to eq(adjusted(480, 640))
  end

  it ":portrait (as second arg)" do
    size_window(:mobile, :portrait)
    expect(dims).to eq(adjusted(480, 640))
  end

  it "to a custom size" do
    size_window(600, 600)
    expect(dims).to eq(adjusted(600, 600))
  end

end
