class Hyperloop::ApplicationPolicy
  # Allow any session to connect:
  always_allow_connection
  # Send all attributes from all public models
  #regulate_all_broadcasts { |policy| policy.send_all }
  # Allow all changes to public models
  #allow_change(to: :all, on: [:create, :update, :destroy]) { true }
end if Rails.env.development?
