module PactStates
  module Exams
    STUDENT_ID = 1901
    EXAM_ID = 2001

    def self.definitions
      proc do
        provider_state "a student with id #{STUDENT_ID} has an exam" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            student = FactoryBot.create(:student, id: STUDENT_ID, trainer: trainer)
            FactoryBot.create(:exam, id: EXAM_ID, student: student)
            PactStateContext.as(FactoryBot.create(:user, :admin))
          end
        end

        provider_state "a student with id #{STUDENT_ID} exists for a new exam" do
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
