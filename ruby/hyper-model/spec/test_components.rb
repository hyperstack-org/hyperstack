RSpec.configure do |config|
  config.before(:all) do
    before_mount do
      class TestComponent < HyperComponent
        param scope: :all
        render(DIV) do
          DIV { "#{TestModel.send(@Scope).count} items" }
          UL { TestModel.send(@Scope).each { |model| LI { model.test_attribute }}}
        end
      end
      class TestComponent2 < HyperComponent
        render do
          "hello"
        end
      end
    end
  end
end
