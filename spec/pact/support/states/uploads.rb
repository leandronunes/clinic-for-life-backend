module PactStates
  module Uploads
    STUDENT_ID = 2201

    def self.definitions
      proc do
        provider_state "a student with id #{STUDENT_ID} exists for uploads" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            student = FactoryBot.create(:student, id: STUDENT_ID, trainer: trainer)
            PactStateContext.as(FactoryBot.create(:user, :personal, trainer: student.trainer))
          end
        end
      end
    end
  end
end
