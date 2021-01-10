require 'spec_helper'

describe 'mutation client integration', js: true do
  it "can load and run the mutation gem on the client" do
    isomorphic do
      class UserSignup < Mutations::Command

        def self.sample_run
          run email: "doit@hyperstack.com", name: "Hyperstack", newsletter_subscribe: true
        end
        required do
          string :email
          string :name, matches: /[a-zA-Z]+/
        end
        optional do
          boolean :newsletter_subscribe
        end
        def execute
          {'email' => email, 'name' => name, 'newsletter_subscribe' => newsletter_subscribe}
        end
      end
    end
    expect_evaluate_ruby("UserSignup.sample_run.result").to eq(UserSignup.sample_run.result)
  end
end
