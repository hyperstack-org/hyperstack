require './tasks/gems'
require './tasks/git'
require './tasks/version'

HYPERLOOP_REPOS =%w[hyper-component hyper-console hyper-mesh hyper-model hyper-operation hyper-react
                    hyper-router hyper-spec hyper-store hyperloop hyperloop-config]

task :default do
  # show usage
end

namespace :spec do
  task :prepare do
    sh %{bundle update}
  end
end
