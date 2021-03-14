require "bundler"
Bundler.require

module OpalSprocketsServer
  def self.opal
    @opal ||= Opal::Sprockets::Server.new do |s|
      s.append_path "app"
      s.main = "application"
      s.debug = ENV["RACK_ENV"] != "production"
    end
  end
end

get "/" do
  <<~HTML
    <!doctype html>
    <html>
      <head>
        #{Opal::Sprockets.javascript_include_tag('application', debug: OpalSprocketsServer.opal.debug, sprockets: OpalSprocketsServer.opal.sprockets, prefix: '/assets')}
      </head>
    </html>
  HTML
end

def app
  Rack::Builder.app do
    map "/assets" do
      run OpalSprocketsServer.opal.sprockets
    end
    run Sinatra::Application
  end
end
