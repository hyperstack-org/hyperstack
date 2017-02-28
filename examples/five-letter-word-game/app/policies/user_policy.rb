# app/policies/application_policy
class UserPolicy
  regulate_instance_connections { self }
end
