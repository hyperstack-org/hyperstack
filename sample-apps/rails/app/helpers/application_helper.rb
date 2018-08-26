module ApplicationHelper
  include Hyperstack::ViewHelpers

  def owl_include_tag(path)
    case Rails.env
    when 'production'
      public, packs, asset = path.split('/')
      path = OpalWebpackManifest.lookup_path_for(asset)
      javascript_include_tag(path)
    when 'development' then javascript_include_tag('http://localhost:3035' + path[0..-4] + '_development' + path[-3..-1])
    when 'test' then javascript_include_tag(path[0..-4] + '_test' + path[-3..-1])
    end
  end
end
