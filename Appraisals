opal_versions = ['0.8', '0.9']
react_versions_map = {
  '13' => '~> 1.3.3',
  '14' => '~> 1.6.2',
  '15' => '~> 1.8.2'
}

opal_versions.each do |opal_v|
  react_versions_map.each do |react_v, react_rails_v|
    appraise "opal-#{opal_v}-react-#{react_v}" do
      gem 'opal', "~> #{opal_v}.0"
      gem 'react-rails', react_rails_v, require: false
    end
  end
end
