# Registered into the single provider example group via `instance_eval` — see
# spec/pact/consumers/backend_provider_spec.rb.
module PactStates
  module PushSubscriptions
    def self.definitions
      proc do
        provider_state "a student is authenticated for push subscriptions" do
          set_up do
            clean_database!
            PactStateContext.as(FactoryBot.create(:user, :student_account))
          end
        end
      end
    end
  end
end
