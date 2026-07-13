module PactStates
  module Feedbacks
    STUDENT_ID = 2401
    FEEDBACK_ID = 2411
    WORKOUT_ID = 2402
    CHECK_IN_ID = 2412
    IN_PROGRESS_WORKOUT_ID = 2403
    IN_PROGRESS_CHECK_IN_ID = 2413

    def self.definitions
      proc do
        provider_state "student #{STUDENT_ID} has a feedback note #{FEEDBACK_ID}" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            student = FactoryBot.create(:student, id: STUDENT_ID, trainer: trainer)
            personal_user = FactoryBot.create(:user, :personal, trainer: trainer)
            workout = FactoryBot.create(:workout, id: WORKOUT_ID, student: student)
            check_in = FactoryBot.create(:workout_check_in, id: CHECK_IN_ID, workout: workout, student: student,
                                                             status: "completed", completed_at: Time.current)
            FactoryBot.create(:feedback, id: FEEDBACK_ID, student: student, author: personal_user,
                                         workout_check_in: check_in, kind: "elogio",
                                         message: "Mandou muito bem no treino de hoje!")
            PactStateContext.as(FactoryBot.create(:user, :admin))
          end
        end

        provider_state "a personal is authenticated to send feedback to student #{STUDENT_ID}" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            student = FactoryBot.create(:student, id: STUDENT_ID, trainer: trainer)
            workout = FactoryBot.create(:workout, id: WORKOUT_ID, student: student)
            FactoryBot.create(:workout_check_in, id: CHECK_IN_ID, workout: workout, student: student,
                                                  status: "completed", completed_at: Time.current)
            PactStateContext.as(FactoryBot.create(:user, :personal, trainer: trainer))
          end
        end

        provider_state "a student is authenticated and attempts to send feedback to student #{STUDENT_ID}" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            student = FactoryBot.create(:student, id: STUDENT_ID, trainer: trainer)
            workout = FactoryBot.create(:workout, id: WORKOUT_ID, student: student)
            FactoryBot.create(:workout_check_in, id: CHECK_IN_ID, workout: workout, student: student,
                                                  status: "completed", completed_at: Time.current)
            PactStateContext.as(FactoryBot.create(:user, :student_account, student: student))
          end
        end

        provider_state "a personal is authenticated to send feedback for student #{STUDENT_ID}'s " \
                       "in-progress check-in #{IN_PROGRESS_CHECK_IN_ID}" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            student = FactoryBot.create(:student, id: STUDENT_ID, trainer: trainer)
            workout = FactoryBot.create(:workout, id: IN_PROGRESS_WORKOUT_ID, student: student)
            FactoryBot.create(:workout_check_in, id: IN_PROGRESS_CHECK_IN_ID, workout: workout, student: student,
                                                  status: "in_progress")
            PactStateContext.as(FactoryBot.create(:user, :personal, trainer: trainer))
          end
        end
      end
    end
  end
end
