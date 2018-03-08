require 'spec_helper'
require 'test_components'
require 'reactive_record_factory'
require 'rspec-steps'

RSpec::Steps.steps 'Load From Json', js: true do

  before(:all) do
    Hyperloop.configuration do |config|
      config.transport = :crud_only
    end
    seed_database
  end

  before(:step) do
    # spec_helper resets the policy system after each test so we have to setup
    # before each test
    stub_const 'TestApplication', Class.new
    stub_const 'TestApplicationPolicy', Class.new
    TestApplicationPolicy.class_eval do
      always_allow_connection
      regulate_all_broadcasts { |policy| policy.send_all }
      allow_change(to: :all, on: [:create, :update, :destroy]) { true }
    end
    size_window(:small, :portrait)
  end

  it '*all key' do
    binding.pry
    evaluate_ruby do
      User.all.count
    end
    # ["User", "all", "*count"] -> {'User': {'unscoped': {'*count': [4]}}}
    evaluate_ruby do
      User.collect { |user| user.id }
    end
    # ["User", "all", "*all"], ["User", "all", "*0", "id"] ->
    # {
    #   'User': {
    #     'all': {
    #       1: {id: [1]}},
    #       2: {id: [2]}},
    #       3: {id: [3]}},
    #       4: {id: [4]}}
    #       '*all': [1, 2, 3, 4]
    #     }
    #   }
    # }
    evaluate_ruby('User.collect { |x| x.first_name }')
    # [["User", ["find_by", {"id":1}], "first_name"], ["User", ["find_by", {"id":2}], "first_name"], ["User", ["find_by", {"id":3}], "first_name"], ["User", ["find_by", {"id":4}], "first_name"]]
    # {"User":{"[\"find_by\",{\"id\":1}]":{"first_name":["Mitch"],"id":[1],"type":[null]},"[\"find_by\",{\"id\":2}]":{"first_name":["Todd"],"id":[2],"type":[null]},"[\"find_by\",{\"id\":3}]":{"first_name":["Adam"],"id":[3],"type":[null]},"[\"find_by\",{\"id\":4}]":{"first_name":["Test1"],"id":[4],"type":[null]}}}}

    # [["User", "all", "*all"], ["User", "all", "*0", "first_name"]] ->
    # {
    #   'User': {
    #     'all': {
    #       1: {first_name: ['Mitch']}},
    #       2: {first_name: ['Todd']}},
    #       3: {first_name: ['Adam']}},
    #       4: {first_name: ['Test1']}}
    #       '*all': [1, 2, 3, 4]
    #     }
    #   }
    # }
    evaluate_ruby('User.all[2].first_name')
    # works like User.all.each...
    # but User.all[2] will insert dummy records for items [0], [1] and [2]
    # but then we only look up `first_name` for [2], so only
    # the [2] (or *2) vector gets pushed to server
    # but strangely this results in the whole array being returned anyway
    # same as above.
    evaluate_ruby('User.all[1].first_name; User.all[3].first_name')
    # actually contains 2 requests, but works the same as above, *1, *3
    # resolve to just * on server.  so *1, and *3 on client are just way to
    # identify the records (via vectors) so on return we correctly match up
    # and update record [1] and record[3] for example.  Point being is that each
    # record has a unique vector... Not sure why that is important...

  end

end

# require 'spec_helper'
# require 'test_components'
# require 'reactive_record_factory'
# require 'rspec-steps'
#
# RSpec::Steps.steps 'Load From Json', js: true do
#
#   before(:all) do
#     seed_database
#   end
#
#   before(:step) do
#     # spec_helper resets the policy system after each test so we have to setup
#     # before each test
#     stub_const 'TestApplication', Class.new
#     stub_const 'TestApplicationPolicy', Class.new
#     TestApplicationPolicy.class_eval do
#       always_allow_connection
#       regulate_all_broadcasts { |policy| policy.send_all }
#       allow_change(to: :all, on: [:create, :update, :destroy]) { true }
#     end
#     size_window(:small, :portrait)
#   end
#
#   it '*all key' do
#     #mount "TestComponent2"
#     x = evaluate_ruby do
#       User.all
#     end
#     binding.pry
#   end
#
# end
