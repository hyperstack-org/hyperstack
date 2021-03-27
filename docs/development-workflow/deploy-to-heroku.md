There are a number of issues and additional items that need to been done when deploying to Heroku (or other production environments.)
Even if not deploying to Heroku these steps will cover most of the gotchas that you will encounter.

If you do find any problems please log an issue, or better yet do a pull request on this page.

1. **You need to use postgresql rather than sqlite or mysql.**  You can find instructions on how to do this online, or better yet when you create your rails app, create it from the beginning with postgresql:  https://www.digitalocean.com/community/tutorials/how-to-set-up-ruby-on-rails-with-postgres

2. **Remove `app/models/application_record.rb`**  This is no longer needed due to a recent rails fix, and confuses Heroku.

3. **Use harmonly uglifier.**  In config/environments/production.rb you need to change this line from:  
`config.assets.js_compressor = :uglifier`   
to  
`config.assets.js_compressor = Uglifier.new(harmony: true)`  

4. **Insure webpacker:compile occurs before assets:precompile:** at the end of the `Rakefile` (in the root directory)  add this line:  
`Rake::Task["assets:precompile"].enhance(['yarn:install', 'webpacker:compile'])`

5. **Setup your database** Make sure you run   
`Heroku run rake db:migrate`

6. **Update your production policies** By default the Hyperstack installer will leave your Policies wide open but **not** in production.   
For a production app you will want to add restrictive Policies to protect your data.  If you just want to get things working on Heroku you can remove the guard from the end of the `policies/application.rb` file.

5. Add `stylesheet_pack_tag`s:   Hyperstack does not automatically pull in the `.css` packs.  Instead you have to add one or both these lines to your layouts, if you are requiring css assets in the pack files:  
`<%= stylesheet_pack_tag    'client_only' %>`    
If you are requiring css libraries in the `client_only.js` pack file   
and    
`<%= stylesheet_pack_tag    'client_and_server' %>`   
 If you are requiring css libraries in the `client_and_server.js` pack file

6. Setup ActionCable (see [full instructions](https://blog.Heroku.com/real_time_rails_implementing_websockets_in_rails_5_with_action_cable#deploying-our-application-to-Heroku) for details)
provision Redis on Heroku `Heroku addons:add redistogo`  
then get the Heroku url: `Heroku config --app action-cable-example | grep REDISTOGO_URL`  
use the url in config/cable.yml (in the production section)  
in config/environments/production.rb add these two lines:   
`config.web_socket_server_url = "wss://your-app.Herokuapp.com/cable" `  
`config.action_cable.allowed_request_origins = ['https://your-app.Herokuapp.com', 'http://action-your-app.Herokuapp.com']`

### On Going Development

After updating anything in the hyperstack initializer you will need to force Heroku to clear the cache:

First install the Heroku-repo plugin (on your console)
`$ Heroku plugins:install Heroku-repo`

and then to clear the cache do:

`$ Heroku repo:purge_cache -a appname`
`$ git commit --allow-empty -m "Purge cache"`
`$ git push Heroku master`
