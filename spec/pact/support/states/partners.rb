# Registered into the single provider example group via `instance_eval` — see
# spec/pact/consumers/backend_provider_spec.rb. Split into one file per domain
# purely for readability; `provider_state` still only works when evaluated in
# that example group's context (it's a DSL method added by `pact/rspec` to
# example groups tagged pact_entity: :provider).
module PactStates
  module Partners
    def self.definitions
      proc do
        provider_state "at least one partner exists" do
          set_up do
            clean_database!
            organization = FactoryBot.create(:organization)
            FactoryBot.create_list(:partner, 2, organization: organization)
            PactStateContext.as(FactoryBot.create(:user, :admin, organization: organization))
          end
        end

        provider_state "no partners exist" do
          set_up do
            clean_database!
            PactStateContext.as(FactoryBot.create(:user, :admin))
          end
        end

        provider_state "an admin is authenticated for partner management" do
          set_up do
            clean_database!
            PactStateContext.as(FactoryBot.create(:user, :admin))
          end
        end

        provider_state "a personal is authenticated for partner management" do
          set_up do
            clean_database!
            PactStateContext.as(FactoryBot.create(:user, :personal))
          end
        end

        provider_state "a partner with id 2102 exists" do
          set_up do
            clean_database!
            organization = FactoryBot.create(:organization)
            FactoryBot.create(:partner, id: 2102, organization: organization)
            PactStateContext.as(FactoryBot.create(:user, :admin, organization: organization))
          end
        end

        provider_state "a partner with id 2103 exists" do
          set_up do
            clean_database!
            organization = FactoryBot.create(:organization)
            FactoryBot.create(:partner, id: 2103, organization: organization)
            PactStateContext.as(FactoryBot.create(:user, :admin, organization: organization))
          end
        end
      end
    end
  end
end
