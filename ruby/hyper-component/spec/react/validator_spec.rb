require "spec_helper"

describe 'React::Validator', js: true do
  describe '#validate' do
    describe "Presence validation" do
      it "should check if required props provided" do
        evaluate_ruby do
          VALIDATOR = React::Validator.new.build do
            requires :foo
            requires :bar
          end
        end
        expect_evaluate_ruby('VALIDATOR.validate({})').to eq(["Required prop `foo` was not specified", "Required prop `bar` was not specified"])
        expect_evaluate_ruby('VALIDATOR.validate({foo: 1, bar: 3})').to eq([])
      end

      it "should check if passed non specified prop" do
        evaluate_ruby do
          VALIDATOR = React::Validator.new.build do
            optional :foo
          end
        end
        expect_evaluate_ruby('VALIDATOR.validate({bar: 10})').to eq(["Provided prop `bar` not specified in spec"])
        expect_evaluate_ruby('VALIDATOR.validate({foo: 10})').to eq([])
      end
    end

    describe "Type validation" do
      it "should check if passed value with wrong type" do
        evaluate_ruby do
          VALIDATOR = React::Validator.new.build do
            requires :foo, type: String
          end
        end
        expect_evaluate_ruby('VALIDATOR.validate({foo: 10})').to eq(["Provided prop `foo` could not be converted to String"])
        expect_evaluate_ruby('VALIDATOR.validate({foo: "10"})').to eq([])
      end

      it "should check if passed value with wrong custom type" do
        evaluate_ruby do
          class Bar; end
          VALIDATOR = React::Validator.new.build do
            requires :foo, type: Bar
          end
        end
        expect_evaluate_ruby('VALIDATOR.validate({foo: 10})').to eq(["Provided prop `foo` could not be converted to Bar"])
        expect_evaluate_ruby('VALIDATOR.validate({foo: Bar.new})').to eq([])
      end

      it 'coerces native JS prop types to opal objects' do
        evaluate_ruby do
          VALIDATOR = React::Validator.new.build do
            requires :foo, type: JS.call(:eval, "(function () { return { x: 1 }; })();")
          end
        end
        expect_evaluate_ruby('VALIDATOR.validate({foo: `{ x: 1 }`})').to eq(["Provided prop `foo` could not be converted to [object Object]"])
      end

      it 'coerces native JS values to opal objects' do
        evaluate_ruby do
          VALIDATOR = React::Validator.new.build do
            requires :foo, type: Array[Integer]
          end
        end
        expect_evaluate_ruby('VALIDATOR.validate({foo: `[ { x: 1 } ]`})').to eq(["Provided prop `foo`[0] could not be converted to #{Integer.name}"])
      end

      it "should support Array[Class] validation" do
        evaluate_ruby do
          VALIDATOR = React::Validator.new.build do
            requires :foo, type: Array[Hash]
          end
        end
        expect_evaluate_ruby('VALIDATOR.validate({foo: [1,"2",3]})').to eq(
          [
            "Provided prop `foo`[0] could not be converted to Hash",
            "Provided prop `foo`[1] could not be converted to Hash",
            "Provided prop `foo`[2] could not be converted to Hash"
          ]
        )
        expect_evaluate_ruby('VALIDATOR.validate({foo: [{},{},{}]})').to eq([])
      end
    end

    describe "Limited values" do
      it "should check if passed value is not one of the specified values" do
        evaluate_ruby do
          VALIDATOR = React::Validator.new.build do
            requires :foo, values: [4,5,6]
          end
        end
        expect_evaluate_ruby('VALIDATOR.validate({foo: 3})').to eq(["Value `3` for prop `foo` is not an allowed value"])
        expect_evaluate_ruby('VALIDATOR.validate({foo: 4})').to eq([])
      end
    end
  end

  describe '#undefined_props' do
    before :each do
      on_client do
        PROPS = { foo: 'foo', bar: 'bar', biz: 'biz', baz: 'baz' }
        VALIDATOR = React::Validator.new.build do
          requires :foo
          optional :bar
        end
      end
    end


    it 'slurps up any extra params into a hash' do
      expect_evaluate_ruby('VALIDATOR.undefined_props(PROPS)').to eq({ "biz" => 'biz', "baz" => 'baz' })
    end

    it 'prevents validate non-specified params' do
      evaluate_ruby do
        VALIDATOR.undefined_props(PROPS)
      end
      expect_evaluate_ruby('VALIDATOR.validate(PROPS)').to eq([])
    end
  end

  describe "default_props" do
    it "should return specified default values" do
      evaluate_ruby do
        VALIDATOR = React::Validator.new.build do
          requires :foo, default: 10
          requires :bar
          optional :lorem, default: 20
        end
      end
      expect_evaluate_ruby('VALIDATOR.default_props').to eq({"foo" => 10, "lorem" => 20})
    end
  end
end
