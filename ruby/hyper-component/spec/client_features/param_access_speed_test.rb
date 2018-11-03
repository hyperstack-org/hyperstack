require 'spec_helper'

describe 'param macro vs instance var access', js: true do

  it "instance var is a lot faster" do
    mount 'Foo', foo: :bar do
      class Foo < HyperComponent
        param :foo

        render(DIV) do
          start_time = Time.now.to_f
          1_000_000.times { x = @foo }
          instance_var_access_time = (Time.now.to_f - start_time)
          x = @foo # param is initialized on first access
          start_time = Time.now.to_f
          1_000_000.times { x = @foo }
          params_access_time = (Time.now.to_f - start_time)
          DIV { "accessing a param directly takes #{instance_var_access_time} micro seconds" }
          DIV { "accessing a param via params wrapper takes #{params_access_time} micro seconds"}
          DIV { "direct access is #{(params_access_time / instance_var_access_time).round(2)} times  faster"}
        end
      end
    end
    binding.pry
  end
end
