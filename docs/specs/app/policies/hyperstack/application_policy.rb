  # /Users/mitch/rubydev/hyperstack/ruby/rails-hyperstack/spec/test_app/app/policies/hyperstack/application_policy.rb

  # Policies regulate access to your public models
  # The following policy will open up full access (but only in development)
  # The policy system is very flexible and powerful.  See the documentation
  # for complete details.
  module Hyperstack
    class ApplicationPolicy
      # Allow any session to connect:
      always_allow_connection
      # Send all attributes from all public models
      regulate_all_broadcasts { |policy| policy.send_all }
      # Allow all changes to models
      allow_change(to: :all, on: [:create, :update, :destroy]) { true }
    end unless Rails.env.production?
  end
