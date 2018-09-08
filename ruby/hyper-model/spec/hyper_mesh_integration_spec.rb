require 'spec_helper'

describe 'HyperMesh Integration', js: true do
  it "The hyper-model gem pulls in hyper-mesh and it works" do
    mount "TestComp"
    expect(page).to have_content('No Todos')
    expect(page).to have_content('No Messages')
    FactoryBot.create(:todo_item, title: 'my first todo')
    expect(page).to have_content('my first todo')
    SendToAll.run(message: "Hello!")
    expect(page).to have_content('Hello!')
  end

  it "can use Hyperloop::Model.load" do
    todo = FactoryBot.create(:todo_item, title: 'another todo')
    expect_promise do
      Hyperloop::Model.load { TodoItem.find_by_title('another todo') }.then { |todo| todo.id }
    end.to eq(todo.id)
  end
end
