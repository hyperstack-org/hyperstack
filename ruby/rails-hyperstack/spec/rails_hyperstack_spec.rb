require "spec_helper"

describe "rails-hyperstack" do
  it "builds a working app", js: true do
    visit "/"
    expect(page).to have_content("App")
  end

  it "installs hyper-model and friends", js: true do
    visit "/"
    expect do
      Hyperstack::Model.load { Sample.count }
    end.on_client_to eq(0)
    on_client do
      Sample.create(name: "sample1", description: "the first sample")
    end
    wait_for_ajax
    expect(Sample.count).to eq(1)
    expect(Sample.first.name).to eq("sample1")
    expect(Sample.first.description).to eq("the first sample")
    expect { Sample.count }.on_client_to eq(1)
  end

  it "implements server_side_auto_require", js: true do
    expect(Sample.super_secret_server_side_method).to be true
    expect do
      Sample.respond_to? :super_secret_server_side_method
    end.on_client_to be_falsy
  end
end
