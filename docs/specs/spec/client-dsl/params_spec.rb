require "spec_helper"

describe "params", :js do
  it "passing an element" do
    mount "App" do
      class Reveal < HyperComponent
        param :content
        render do
          BUTTON { "#{@show ? 'hide' : 'show'} me" }
          .on(:click) { mutate @show = !@show }
          content.render if @show
        end
      end

      class App < HyperComponent
        render do
          Reveal(content: DIV { "I came from the App" })
        end
      end
    end
    expect(find("button").text).to eq "show me"
    expect(page).not_to have_content("I came from the App", wait: 0)
    find("button").click
    expect(find("button").text).to eq "hide me"
    expect(page).to have_content("I came from the App")
  end
end
