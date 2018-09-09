opal_versions = ['0.8', '0.9', '0.10']
react_versions_map = {
  '13' => '~> 1.3.3',
  '14' => '~> 1.6.2',
  '15' => '~> 1.10.0'
}
opal_rails_versions_map = {
  '0.8' => '~> 0.8.1',
  '0.9' => '~> 0.9.0',
  '0.10' => '~> 0.9.0',
}

opal_versions.each do |opal_v|
  react_versions_map.each do |react_v, react_rails_v|
    appraise "opal-#{opal_v}-react-#{react_v}" do
      ruby ">= 1.9.3"
      gem 'opal', "~> #{opal_v}.0"
      gem 'opal-rails', opal_rails_versions_map[opal_v]
      gem 'react-rails', react_rails_v, require: false
    end
  end
end


appraise "opal-master-react-15" do
  ruby '>= 2.0.0'
  gem 'opal', git: 'https://github.com/opal/opal.git'
  gem "opal-sprockets", git: 'https://github.com/opal/opal-sprockets.git'
  gem 'opal-rails', '~> 0.9.4'
  gem 'react-rails', '~> 2.4.0', require: false
end
