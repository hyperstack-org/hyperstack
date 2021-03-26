require "spec_helper"

describe "interfacing to javascript components", :js do
  it "can import a single JS component" do
    mount "MyBigApp" do
      %x{
        window.SayHello = class extends React.Component {
          constructor(props) {
            super(props);
            this.displayName = "SayHello"
          }
          render() { return React.createElement("div", null, "Hello ", this.props.name); }
        }
      }

      class SayHello < HyperComponent
        imports 'SayHello'
      end

      class MyBigApp < HyperComponent
        render(DIV) do
          # SayHello will now act like any other Hyperstack component
          SayHello name: 'Matz'
        end
      end
    end
    expect(page).to have_content "Hello Matz"
  end
  it "will auto import a whole library" do
    mount "App" do
      class App < HyperComponent
        render do
          Mui::Button(variant: :contained, color: :primary) { "Click me" }.on(:click) do
            alert 'you clicked the primary button!'
          end
          Button(variant: :contained, color: :secondary) { "Click me" }.on(:click) do
            alert 'you clicked the secondary button!'
          end
        end
      end
    end
    find('button.MuiButton-containedPrimary').click
    expect(accept_alert).to eq "you clicked the primary button!"
    find('button.MuiButton-containedSecondary').click
    expect(accept_alert).to eq "you clicked the secondary button!"
  end

  it "importing images" do
    mount "App" do
      class HyperComponent
        def self.img_src(file_path)
          @img_map ||= Native(`webpackImagesMap`)
          @img_map["./#{file_path}"]
        end
        def img_src(file_path)
          HyperComponent.img_src(file_path)
        end
      end
      class App < HyperComponent
        render do
          IMG(src: img_src("hyperloop-logo-medium-pink.png"))
        end
      end
    end
    expect(File).to exist "#{Rails.root}/public#{URI(find('img')[:src]).path}"
  end

  it "fun with jQuery" do
    mount "App" do
      class App < HyperComponent
        render(FRAGMENT) do
          DIV(id: :inner_div_1) { 'hello' }
          DIV(id: :inner_div_2) { 'goodby' }
        end
      end
    end
    on_client { jQ['#inner_div_1'].html = 'zoom' }
    expect(find('#inner_div_1').text).to eq 'zoom'
    on_client { Element['#inner_div_1'].html = 'foobar' }
    expect(find('#inner_div_1').text).to eq 'foobar'
  end

  it "using dom_node" do
    mount "App" do
      class App < HyperComponent
        render(FRAGMENT) do
          INPUT(id: :text_1)
          FocusedInput()
        end
      end
      class FocusedInput < HyperComponent
        after_mount do
          jQ[dom_node].focus
        end
        render do
          INPUT(id: :text_2)
        end
      end
    end
    page.send_keys 'hello'
    expect(find('input#text_2').value).to eq 'hello'
  end

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
          Reveal(content: ~DIV { 'I came from the App' })
        end
      end
    end
    expect(find('button').text).to eq 'show me'
    expect(page).not_to have_content('I cam from the App')
    find('button').click
    expect(find('button').text).to eq 'hide me'
    expect(page).to have_content('I cam from the App')
  end
end
