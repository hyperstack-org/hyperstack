each level copies instance variables from outer levels
there (seems) to be no way to create a config.before(:all) that works for each level of describe
but it could be done like this:

```ruby
RSpec.configure do |config|
  config.before(:each) do |example|
    puts "#{example} - client_loaded: #{example.example_group.metadata[:client_loaded?]}"
    unless example.example_group.metadata[:client_loaded?]
      example.example_group.metadata[:client_loaded?] = true
      # do whatever needs to be done once per context
    end
  end
end
```

```ruby
describe "outer describe" do
  before(:all) do
    # mount, before_mount, on_client, insert_html, etc all queue up
  end
  it "spec 1" do
    # outer describe before(:all) client stuff executed here
    puts "spec 1"
  end
  describe "inner describe 1" do
    before(:all) do
      # reload <- will restore client context to state at end of parent before(:all)
    end
    it "spec 1.1" do
      puts "spec 1.1"
    end
    it "spec 1.2" do
      puts "spec 1.2"
    end
  end
  describe "inner describe 2" do
    it "spec 2.1" do
      puts "spec 2.1"
    end
    it "spec 1.2" do
      puts "spec 2.2"
    end
  end
  it "spec 2" do
    puts "spec 2"
  end
end
```
