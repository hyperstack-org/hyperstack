require "spec_helper"
describe "The App", no_reset: true, js: true do
  it "works" do
    expect { 12 + 12 }.on_client_to eq 24
  end
end
