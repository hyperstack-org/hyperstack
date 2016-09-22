# app/policies/application_policy
class ApplicationPolicy
  always_allow_connection
  regulate_all_broadcasts { |policy| policy.send_all }
  allow_change(to: :all, on: [:create, :update, :destroy]) { true }
end
