namespace :hyperloop do
  namespace :git do
    desc "create new branch in local hyperloop repos, requires branch name as argument"
    task :create_branch, [:branch_name] do |_, arg|
      branch = arg[:branch_name]
      if branch.nil?
        puts "please use: rake hyperloop:git:create_branch[your_branch_name]"
        return
      end
      HYPERLOOP_REPOS.each do |repo|
        Dir.chdir(File.join('..', repo)) do
         puts "\033[0;32mCreating new branch for #{repo}:\033[0;30m\t#{`git branch #{branch}`}"
        end
      end
    end

    desc "checkout branch in local hyperloop repos, requires branch name as argument"
    task :co_branch, [:branch_name] do |_, arg|
      branch = arg[:branch_name]
      if branch.nil?
        puts "please use: rake hyperloop:git:co_branch[your_branch_name]"
        return
      end
      HYPERLOOP_REPOS.each do |repo|
        Dir.chdir(File.join('..', repo)) do
         puts "\033[0;32mChecking out branch for #{repo}:\033[0;30m\t#{`git checkout #{branch}`}"
        end
      end
    end

    desc "show current branch in local hyperloop repos"
    task :show_branch do
      HYPERLOOP_REPOS.each do |repo|
        Dir.chdir(File.join('..', repo)) do
          puts "\033[0;32mCurrent branch of #{repo}:\033[0;30m\t#{`git rev-parse --abbrev-ref HEAD`}"
        end
      end
    end

    desc "commit all changes in all repos in their current branches, requires commit_message"
    task :commit, [:commit_message] do |_, arg|
      message = arg[:commit_message]
      if message.nil?
        puts "please use: rake hyperloop:git:commit[your_commit_message]"
        return
      end
      HYPERLOOP_REPOS.each do |repo|
        Dir.chdir(File.join('..', repo)) do
          puts "\033[0;32mCommitting #{repo}:\033[0;30m\t#{`git commit -am "#{message}"`}"
        end
      end
    end

    desc "push all local hyperloop repos, accepts remote and branch as arguments, defaults to origin and current branch"
    task :push, [:remote, :branch] do |_, arg|
      HYPERLOOP_REPOS.each do |repo|
        Dir.chdir(File.join('..', repo)) do
          puts "\033[0;32mPushing #{repo}:\033[0;30m"
          puts
          if arg[:remote] && arg[:branch]
            puts `git push --set-upstream #{arg[:remote]} #{arg[:branch]}`
          else
            puts `git push`
          end
          puts
          puts
        end
      end
    end

    desc "update remotes and show git status for local hyperloop repos"
    task :status do
      HYPERLOOP_REPOS.each do |repo|
        Dir.chdir(File.join('..', repo)) do
          puts "\033[0;32mStatus for #{repo}:\033[0;30m"
          `git remote update`    
          puts
          puts `git status`
          puts
          puts
        end
      end
    end
  end
end