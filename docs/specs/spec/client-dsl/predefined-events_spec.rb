# spec/client-dsl/predefined-events_spec.rb
require "spec_helper"

describe "predefined-events.md", :js do
  it "The YouSaid Component" do
    mount "YouSaid" do
      class YouSaid < HyperComponent
        state_accessor :value
        render(DIV) do
          INPUT(value: value)
          .on(:key_down) do |e|
            next unless e.key_code == 13

            alert "You said: #{value}"
            self.value = ""
          end
          .on(:change) do |e|
            self.value = e.target.value
          end
        end
      end
    end
    2.times do
      expect(
        accept_alert { find("input").send_keys "hello", :enter }
      ).to eq "You said: hello"
    end
  end

  it "The YouSaid Component - with Enter Event" do
    mount "YouSaid" do
      class YouSaid < HyperComponent
        state_accessor :value
        render(DIV) do
          INPUT(value: value)
          .on(:enter) do
            alert "You said: #{value}"
            self.value = ""
          end
          .on(:change) do |e|
            self.value = e.target.value
          end
        end
      end
    end
    2.times do
      expect(
        accept_alert { find("input").send_keys "hello", :enter }
      ).to eq "You said: hello"
    end
  end

  it "Drag and Drop Demo" do
    mount "DragAndDrop" do
      class DragAndDrop < HyperComponent
        render do
          DIV(id: :div1, style: { width: 350, height: 70, padding: 10, border: '1px solid #aaaaaa' })
          .on(:drop) do |evt|
            evt.prevent_default
            data = `#{evt.native_event}.native.dataTransfer.getData("text")`
            `#{evt.target}.native.appendChild(document.getElementById(data))`
          end
          .on(:drag_over, &:prevent_default)

          IMG(id: :drag1, src: "https://www.w3schools.com/html/img_logo.gif", draggable: "true", width: 336, height: 69)
          .on(:drag_start) do |evt|
            `#{evt.native_event}.native.dataTransfer.setData("text", #{evt.target}.native.id)`
          end
        end
      end
    end
    source = find("img")
    target = find("div#div1")
    expect(source.find(:xpath, "..")[:id]).not_to eq target
    source.drag_to target
    expect(source.find(:xpath, "..")).to eq target
  end
end
