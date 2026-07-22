# Registered into the single provider example group via `instance_eval` — see
# spec/pact/consumers/backend_provider_spec.rb.
module PactStates
  module Organizations
    UPDATE_ID = 802
    FORBIDDEN_ID = 803

    def self.definitions
      proc do
        provider_state "at least one organization exists" do
          set_up do
            clean_database!
            FactoryBot.create(:organization, name: "Clínica Exemplo", domain: "clinica-exemplo")
          end
        end

        provider_state "an admin is authenticated for organization #{PactStates::Organizations::UPDATE_ID}" do
          set_up do
            clean_database!
            organization = FactoryBot.create(:organization, id: PactStates::Organizations::UPDATE_ID)
            PactStateContext.as(FactoryBot.create(:user, :admin, organization: organization))
          end
        end

        provider_state "a personal is authenticated for organization #{PactStates::Organizations::FORBIDDEN_ID}" do
          set_up do
            clean_database!
            organization = FactoryBot.create(:organization, id: PactStates::Organizations::FORBIDDEN_ID)
            PactStateContext.as(FactoryBot.create(:user, :personal, organization: organization))
          end
        end
      end
    end
  end
end
