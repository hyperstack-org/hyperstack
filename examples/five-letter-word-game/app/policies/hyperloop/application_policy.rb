class Hyperloop::ApplicationPolicy
  always_allow_connection unless Rails.env.production?
end
