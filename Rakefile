require './ruby/version'
desc 'Publish hyperstack gems to private dir'
task :publish do
  base_path = ENV['PWD']
  sh "gem", "install", "geminabox"
  #  hyper-console
  %w{
  hyper-component
hyper-i18n
hyper-model
hyper-operation
hyper-router
hyper-spec
hyper-state
hyper-store
hyper-trace
hyperstack-config
rails-hyperstack}.each do|gem|
    puts "Publishing #{gem} gem"
    Dir.chdir("#{base_path}/ruby/#{gem}") do
      sh 'gem' ,'build', "#{gem}.gemspec"
      sh   'gem' ,'inabox' ,"#{gem}-#{Hyperstack::VERSION.tr("'",'')}.gem" ,'-g' ,"https://michail:#{ENV['GEM_SERVER_KEY']}@gems.ru.aegean.gr"
    end

  end
end
