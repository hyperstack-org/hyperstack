namespace :hyperloop do
  namespace :gems do
    desc "build all hyperloop gems"
    task :build do
      HYPERLOOP_REPOS.each do |repo|
        Dir.chdir(File.join('..', repo)) do
          puts "\033[0;32mBuilding gem for #{repo}:\033[0;30m"
          `gem build #{repo}`
        end
      end
    end

    desc "upload all hyperloop gems to the inabox gem server, accepts host as argument"
    task :inabox, [:host] do |_, arg|
      host = arg[:host]
      HYPERLOOP_REPOS.each do |repo|
        Dir.chdir(File.join('..', repo)) do
          best_time = Time.new(1970, 1, 1)
          last_created_gem_fst = Dir.glob('*.gem').reduce([best_time, '']) do |gem_fst, gem|
            mtime = File.stat(gem).mtime
            mtime > gem_fst[0] ? [mtime, gem] : gem_fst
          end
          
          if host
            puts "pushing #{last_created_gem_fst[1]} to #{host}"
            `gem inabox #{last_created_gem_fst[1]} -g #{host}`
          else
            puts "pushing #{last_created_gem_fst[1]}"
            `gem inabox #{last_created_gem_fst[1]}`
          end
        end
      end
    end

    desc "upload all hyperloop gems to rubygems"
    task :push do
      HYPERLOOP_REPOS.each do |repo|
        Dir.chdir(File.join('..', repo)) do
          best_time = Time.new(1970, 1, 1)
          last_created_gem_fst = Dir.glob('*.gem').reduce([best_time, '']) do |gem_fst, gem|
            mtime = File.stat(gem).mtime
            mtime > gem_fst[0] ? [mtime, gem] : gem_fst
          end
          puts "pushing #{last_created_gem_fst[1]}"
          `gem push #{last_created_gem_fst[1]}`
        end
      end
    end
  end
end