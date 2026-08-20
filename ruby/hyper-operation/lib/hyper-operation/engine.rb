module Hyperstack
  class Engine < ::Rails::Engine
    isolate_namespace Hyperstack
    config.generators do |g|
      g.test_framework      :rspec,        :fixture => false
      g.fixture_replacement :factory_bot, :dir => 'spec/factories'
      g.assets false
      g.helper false
    end

    # In development, code reloading wipes the regulations that policies
    # install on model singleton classes, and Hyperstack.reset_operations
    # only const_gets the policy once at boot. Re-reference the policy on
    # every prepare cycle so its class body (the regulations) re-runs
    # against the freshly reloaded models. Without this, the first code
    # edit after boot silently 403s every ReactiveRecord fetch with
    # AccessViolation:scoped_permission_not_granted.
    config.to_prepare do
      %w[ApplicationPolicy Hyperstack::ApplicationPolicy].each do |policy|
        begin
          Object.const_get policy
        rescue LoadError, NameError
          nil
        end
      end
    end
  end
end
