module PactStates
  module Biomechanics
    STUDENT_ID = 1201
    ASSESSMENT_ID = 1301

    def self.definitions
      proc do
        provider_state "a student with id #{STUDENT_ID} has a biomechanical assessment" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            student = FactoryBot.create(:student, id: STUDENT_ID, trainer: trainer)
            FactoryBot.create(:biomechanical_assessment, id: ASSESSMENT_ID, student: student)
            PactStateContext.as(FactoryBot.create(:user, :admin))
          end
        end

        provider_state "a student with id #{STUDENT_ID} exists for biomechanical assessments" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            FactoryBot.create(:student, id: STUDENT_ID, trainer: trainer)
            PactStateContext.as(FactoryBot.create(:user, :admin))
          end
        end
      end
    end
  end
end
