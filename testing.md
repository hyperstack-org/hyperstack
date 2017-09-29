# Testing hyper-mes~~s~~h

## Local:

1. in hyper-mesh dir : `bundle`
2. choose your database gem, mysql2 or pg, for the test_app in hyper-mesh/spec/test_app/Gemfile
3. `cd hyper-mesh/spec/test_app` and `bundle`
4. setup ypur database and configure database settings in hyper-mesh/spec/test_app/config/database.yml
5. `cd hyper-mesh/spec/test_app` and `rails db:setup`
6. finally `cd hyper-mesh` and `rake spec`

## Using TravisCI

1. log in to TravisCI.org with github account
2. turn testing on for your hyper-mesh fork
3. push a commit to github
4. travis will schedule a run
