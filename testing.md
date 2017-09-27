# Testing hyper-mes~~s~~h

1. For now install ruby-2.2.8
2. in hyper-mesh dir : `bundle`
3. choose your database gem, mysql2 or pg, for the test_app in hyper-mesh/spec/test_app/Gemfile
4. `cd hyper-mesh/spec/test_app` and `bundle`
5. setup ypur database and configure database settings in hyper-mesh/spec/test_app/config/database.yml
6. `cd hyper-mesh/spec/test_app` and `rails db:setup`
7. finally `cd hyper-mesh` and `rake spec`
