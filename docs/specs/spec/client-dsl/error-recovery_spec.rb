require "spec_helper"
describe "error-recovery.md", :js do
  describe "example 1 and 2" do
    before(:each) do
      before_mount do
        class ContentWhichFailsSometimes < HyperComponent
          class << self
            mutator :fail_now! do
              @fail_now = true
            end
            def time_to_fail?
              return unless @fail_now

              @fail_now = false
              raise "well not so good"
            end
          end
          render do
            DIV(id: :tp_1) { "I'm okay #{Time.now}" }
            ContentWhichFailsSometimes.time_to_fail?
          end
        end
        class ReportError < Hyperstack::Operation
          param :err
        end
      end
    end

    it "recovers from failure 1" do
      mount "App" do
        class App < HyperComponent
          render(DIV) do
            H1 { "Welcome to Our App" }
            if @failure_fall_back
              DIV { 'Whoops we had a little problem!' }
              BUTTON { 'retry' }.on(:click) { mutate @failure_fall_back = false }
            else
              ContentWhichFailsSometimes()
            end
          end

          rescues do |err|
            @failure_fall_back = true
            ReportError.run(err: err)
          end
        end
      end
      expect(page).to have_content "I'm okay"
      on_client { ContentWhichFailsSometimes.fail_now! }
      expect(page).to have_content "Whoops we had a little problem!"
      find("button").click
      expect(page).to have_content "I'm okay"
    end

    it "recovers from failure 2" do
      mount "App" do
        class App < HyperComponent
          render(DIV) do
            H1 { "Welcome to Our App" }
            ContentWhichFailsSometimes()
          end

          rescues do
          end
        end
      end
      expect(page).to have_content "I'm okay"
      last_rendered_message = find('div#tp_1').text
      Timecop.travel(1.minute) do
        on_client { ContentWhichFailsSometimes.fail_now! }
        expect(page).to have_content "I'm okay"
        expect(find('div#tp_1').text).not_to eq last_rendered_message
      end
    end

    it "rescue block arguments" do
      mount "App" do
        class App < HyperComponent
          render(DIV) do
            H1 { "Welcome to Our App" }
            ContentWhichFailsSometimes()
          end

          rescues do |*args|
            puts "I received: [#{args}]"
            args.each do |arg|
              puts arg.class
            end
            puts args.first.backtrace
            App.err = args
          end
          class << self
            attr_accessor :err
          end
        end
      end
      on_client { ContentWhichFailsSometimes.fail_now! }
      expect { App.err[0] }.on_client_to eq "well not so good"
      expect { App.err[0].class }.on_client_to eq "RuntimeError"
      expect { App.err[0].respond_to? :backtrace }.on_client_to be_truthy
      expect { App.err[0].respond_to? :message }.on_client_to be_truthy
      expect { App.err[1].keys }.on_client_to eq ["componentStack"]
    end

    it "rescuing from callbacks" do
      mount "App" do
        class InnerApp < HyperComponent
          before_mount do
            raise "whoops" unless App.failed_once
          end
          render {}
        end
        class App < HyperComponent
          class << self
            attr_accessor :failed_once
          end
          render(DIV) do
            H1 { "Welcome to Our App" }
            InnerApp()
          end

          rescues do |*args|
            App.failed_once = true
            puts "rescues.  #{App.object_id} #{!!App.failed_once}"
          end
        end
      end
      on_client { ContentWhichFailsSometimes.fail_now! }
      expect(page).to have_content "Welcome to Our App"
    end



  end
end
