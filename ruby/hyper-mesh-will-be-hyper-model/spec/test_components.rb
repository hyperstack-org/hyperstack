RSpec.configure do |config|
  config.before(:all) do
    on_client do
      class TestComponent < React::Component::Base
        param scope: :all
        render(:div) do
          div { "#{TestModel.send(params.scope).count} items" }
          ul { TestModel.send(params.scope).each { |model| li { model.test_attribute }}}
        end
      end
      class TestComponent2 < React::Component::Base
        render do
          "hello"
        end
      end
    end
  end
end
