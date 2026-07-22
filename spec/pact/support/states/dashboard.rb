module PactStates
  module Dashboard
    def self.definitions
      proc do
        provider_state "an admin with dashboard data is authenticated" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            FactoryBot.create(:student, trainer: trainer, status: "active")
            PactStateContext.as(FactoryBot.create(:user, :admin, organization: trainer.organization))
          end
        end
      end
    end
  end
end
