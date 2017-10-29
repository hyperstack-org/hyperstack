class Hello < Hyperloop::Component

  state time: Time.now

  after_mount do
    every(1) { mutate.time Time.now }
  end

  render(DIV) do
    DIV { "Hello! The time is #{state.time}." }
    DIV { INPUT(id: :message1); BUTTON { "send"}
    .on(:click) { SendToAll.run(message: Element['#message1'].value) } }
    DIV { INPUT(id: :message2); BUTTON { "send2"}
    .on(:click) { Operations::NestedSendToAll.run(message: Element['#message2'].value) } }
    if Messages.all.count == 0
      DIV { "No Messages" }
    else
      UL do
        Messages.all.each do |message|
          LI { message }
        end
      end
    end
  end
end
