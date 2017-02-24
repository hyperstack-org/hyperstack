class Chat < React::Component::Base
  render(DIV) do
    SPAN { 'hello world' }
    Alerts()
    INPUT(id: :message)
    BUTTON { 'send' }.on(:click) { Announcement.run(message: Element['#message'].value ) }
  end
end

class Alerts < React::Component::Base
  #include Hyperloop::Store::Mixin
  # for simplicity we are going to merge our store with the component
  #state alert_messages: [] scope: :class
  export_state :messages
  on_mount do
    Alerts.messages! []
  end
  # not using hyper store mixin yet so manually wire it up
  Announcement.on_dispatch { |params| Alerts.messages! << params.message }

  render(DIV, class: :alerts) do
    UL do
      Alerts.messages.each do |message|
        LI do
          SPAN { message }
          BUTTON { 'dismiss' }.on(:click) { Alerts.messages!.delete(message) }
        end
      end
    end
  end
end
