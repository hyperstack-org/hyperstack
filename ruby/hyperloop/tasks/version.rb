namespace :hyperloop do
  namespace :version do

    def file_version_for(repo)
      case repo
      when 'hyper-component' then ['./lib/hyperloop/component/version', 'Hyperloop::Component::VERSION']
      when 'hyper-console' then ['./lib/hyperloop/console/version', 'Hyperloop::Console::VERSION']
      when 'hyper-mesh' then ['./lib/hypermesh/version', 'Hypermesh::VERSION']
      when 'hyper-model' then ['./lib/hyperloop/model/version', 'Hyperloop::Model::VERSION']
      when 'hyper-operation' then ['./lib/hyper-operation/version', 'Hyperloop::Operation::VERSION']
      when 'hyper-react' then ['./lib/reactive-ruby/version', 'React::VERSION']
      when 'hyper-router' then ['./lib/hyper-router/version', 'HyperRouter::VERSION']
      when 'hyper-spec' then ['./lib/hyper-spec/version', 'HyperSpec::VERSION']
      when 'hyper-store' then ['./lib/hyper-store/version', 'HyperStore::VERSION']
      when 'hyperloop' then ['./lib/hyperloop/version', 'Hyperloop::VERSION']
      when 'hyperloop-config' then ['./lib/hyperloop/config/version', 'Hyperloop::Config::VERSION']
      end
    end

    def set_version(repo, version, hrversion = nil)
      fv_arr = file_version_for(repo)
      out = ''
      File.open(fv_arr[0] + '.rb', 'rt+') do |f|
        f.each_line do |line|
          if /\sVERSION/.match?(line)
            out << line.sub(/VERSION = ['"][\w.-]+['"]/, "VERSION = '#{version}'" )
          elsif hrversion && /\sROUTERVERSION/.match?(line)
            out << line.sub(/ROUTERVERSION = ['"][\w.-]+['"]/, "ROUTERVERSION = '#{hrversion}'" )
          elsif /\sHYPERLOOP_VERSION/.match?(line)
            out << line.sub(/HYPERLOOP_VERSION = ['"][\w.-]+['"]/, "HYPERLOOP_VERSION = '#{hrversion}'" )
          else
            out << line
          end
        end
        f.truncate(0)
        f.pos = 0
        f.write(out)
      end
    end

    desc "set gems version to, requires gem version and hyper-router gem version as arguments"
    task :set, [:version, :hrversion] do |_, arg|
      version = arg[:version]
      hrversion = arg[:hrversion]
      if version.nil? || hrversion.nil?
        puts "please use: rake hyperloop:version:set[the_new_gem_version,the_new_hyper_router_version]"
        return
      end
      HYPERLOOP_REPOS.each do |repo|
        Dir.chdir(File.join('..', repo)) do
          if repo == 'hyper-router'
            set_version(repo, hrversion, version)
            sv = hrversion
          elsif repo == 'hyperloop'
            set_version(repo, version, hrversion)
            sv = "#{version} #{hrversion}"
          else
            set_version(repo, version)
            sv = version
          end
          puts "\033[0;32m#{repo} now at:\033[0;30m\t#{sv}"
        end
      end
    end

    desc "show current gem versions"
    task :show do
      HYPERLOOP_REPOS.each do |repo|
        Dir.chdir(File.join('..', repo)) do
          fv_arr = file_version_for(repo)
          require fv_arr[0]
          puts "\033[0;32m#{repo}:\033[0;30m\t#{Object.const_get(fv_arr[1])}"
        end
      end
    end
  end
end