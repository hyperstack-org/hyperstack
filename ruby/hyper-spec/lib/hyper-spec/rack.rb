require 'hyper-spec'

class HyperSpecTestController < SimpleDelegator
  include HyperSpec::ControllerHelpers

  class << self
    attr_reader :sprocket_server
    attr_reader :asset_path

    def wrap(app:, append_path: 'app', asset_path: '/assets')
      @sprocket_server = Opal::Sprockets::Server.new do |s|
        s.append_path append_path
      end

      @asset_path = asset_path

      ::Rack::Builder.app(app) do
        map "/#{HyperSpecTestController.route_root}" do
          use HyperSpecTestController
        end
      end
    end
  end

  def sprocket_server
    self.class.sprocket_server
  end

  def asset_path
    self.class.asset_path
  end

  def ping!
    [204, {}, []]
  end

  def application!(file)
    @page << Opal::Sprockets.javascript_include_tag(
      file,
      debug: true,
      sprockets: sprocket_server.sprockets,
      prefix: asset_path
    )
  end

  def json!
    @page << Opal::Sprockets.javascript_include_tag(
      'json',
      debug: true,
      sprockets: sprocket_server.sprockets,
      prefix: asset_path
    )
  end


  def style_sheet!(_file_); end

  def deliver!
    [200, { 'Content-Type' => 'text/html' }, [@page]]
  end

  def call(env)
    __setobj__(Rack::Request.new(env))
    params[:id] = path.split('/').last
    test
  end
end
