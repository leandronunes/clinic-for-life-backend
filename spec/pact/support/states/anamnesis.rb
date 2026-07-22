module PactStates
  module Anamnesis
    STUDENT_ID = 1001

    def self.definitions
      proc do
        provider_state "a student with id #{STUDENT_ID} exists for anamnesis" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            FactoryBot.create(:student, id: STUDENT_ID, trainer: trainer)
            PactStateContext.as(FactoryBot.create(:user, :admin, organization: trainer.organization))
          end
        end
      end
    end
  end
end
