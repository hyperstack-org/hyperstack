# hyper-gate
Policy for Hyperstack

## Installation
take this from the repo
then in your shell:
`$ hyper-gate-installer`

This will create directories and install a default gate handler in your projects `hyperstack/handlers` directory or
`app/hyperstack/handlers`, depending on your config.

## Usage
You may modify the installed GateHandler. See the gate_handler.rb file.
To create a policy for a class, name the policy after the class + 'Policy'.
For example, for a class 'SuperDuper' the policy must be named 'SuperDuperPolicy'

Place the policy file in your projects `hyperstack/policies` directory or `app/hyperstack/policies`, depending on your config.

Policies get "compiled" so that errors in the policy definition get caught early on.
Policy params get checked before the rules are executed.
Params must be qualified. The result of the qualification must be a boolean of class TrueClass or FalseClass.
Rules are compiled to a set of booleans and are executed on and with booleans only and evaluate to a boolean.

Example Policy:
```ruby
class SuperDuperPolicy
  include Hyperstack::Gate::PolicyDefinition
  
  qualify :member_is_valid do |*policy_context|
    # policy_context is whatever is passed to Hyperstack::Gate.authorize
  
    # current_user is available as instance method and is passed to the policy initializer by Hyperstack::Gate.authorize
    current_user.class == Member # result must be a boolean
  end
  
  qualify :member_is_admin do |*policy_context|
    current_user.is_admin == 't' # must make sure its a boolean, not some 't' or '1' from the ORM or DB
  end
  
  # :fetch is the action as passed by Hyperstack::Gate.authorize
  policy_for :fetch do
    # there are following conditions available:
    # :if, :and_if, :if_not, :and_if_not, :unless 
    # each must be followed by a qualifier  
    Allow if: :member_is_valid
  end
  
  policy_for :save do
    Allow if: :member_is_valid, and_if: :member_is_admin
    # or expressed in other terms:
    Deny if_not: :member_is_admin 
  end
end
```
In a component on the client or in any class anywhere, us authorize for example like this:
```ruby
class Mycomponent < Hyperstack::Component
  include Hyperstack::Gate # include this
  
  render do
    if authorized?(GlobalStore.current_user, 'SuperDuper', :save) # then use this
      SaveButton(text: 'Save')
    else
      SaveButton(disabled: true)
    end
  end
end
```
Data required by the qualify of the policy should be available on the client!

After including Hyperstack::Gate there are available:
```ruby
authorize(user, class_name, action, *policy_context)
# result is a Hash, one of:
# { allowed: { expected_values: expected_values, qualified_values: qualified_values }}
# { denied: { expected_values: expected_values, qualified_values: qualified_values }}
# { denied: "No policy for #{class_name} #{action}!"}
authorized?(user, class_name, action, *policy_context)
# result is a boolean
authorize!(user, class_name, action, *policy_context)
# will raise a exception if denied

# (for now only) on the client is available:
promise_authorize(user, class_name, action, *policy_context).then do |result|
  # result is the allowed hash, as above
end.fail do |result|
  # result is the denied hash, as above
end 
# authorize gets executed on the server
# result is a promise, once resolved its value will be the result of the server side authorize call
# policy_context must be JSON serializable in this case
  
# otherwise policy_context is completely up to you and is passed to the qualifiers 
```
