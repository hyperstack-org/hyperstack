# app/policies/application_policy
class Hyperloop::ApplicationPolicy
  # Allow any session to connect:
  always_allow_connection
end if Rails.env.development?
