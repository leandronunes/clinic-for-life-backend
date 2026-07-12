module PactStates
  module Feedbacks
    STUDENT_ID = 2401
    FEEDBACK_ID = 2411

    def self.definitions
      proc do
        provider_state "a student with id #{STUDENT_ID} exists for feedback" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            FactoryBot.create(:student, id: STUDENT_ID, trainer: trainer)
            PactStateContext.as(FactoryBot.create(:user, :admin))
          end
        end

        provider_state "student #{STUDENT_ID} has a feedback note #{FEEDBACK_ID}" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            student = FactoryBot.create(:student, id: STUDENT_ID, trainer: trainer)
            personal_user = FactoryBot.create(:user, :personal, trainer: trainer)
            FactoryBot.create(:feedback, id: FEEDBACK_ID, student: student, author: personal_user,
                                         kind: "elogio", message: "Mandou muito bem no treino de hoje!")
            PactStateContext.as(FactoryBot.create(:user, :admin))
          end
        end

        provider_state "a personal is authenticated to send feedback to student #{STUDENT_ID}" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            FactoryBot.create(:student, id: STUDENT_ID, trainer: trainer)
            PactStateContext.as(FactoryBot.create(:user, :personal, trainer: trainer))
          end
        end

        provider_state "a student is authenticated and attempts to send feedback to student #{STUDENT_ID}" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            student = FactoryBot.create(:student, id: STUDENT_ID, trainer: trainer)
            PactStateContext.as(FactoryBot.create(:user, :student_account, student: student))
          end
        end
      end
    end
  end
end
