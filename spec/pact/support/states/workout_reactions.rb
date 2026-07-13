module PactStates
  module WorkoutReactions
    STUDENT_ID = 2501
    WORKOUT_ID = 2511
    CHECK_IN_ID = 2521
    IN_PROGRESS_CHECK_IN_ID = 2522

    def self.definitions
      proc do
        provider_state "a personal is authenticated to react to student #{STUDENT_ID}'s " \
                       "completed check-in #{CHECK_IN_ID}" do
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

        provider_state "a personal is authenticated to react to student #{STUDENT_ID}'s " \
                       "in-progress check-in #{IN_PROGRESS_CHECK_IN_ID}" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            student = FactoryBot.create(:student, id: STUDENT_ID, trainer: trainer)
            workout = FactoryBot.create(:workout, id: WORKOUT_ID, student: student)
            FactoryBot.create(:workout_check_in, id: IN_PROGRESS_CHECK_IN_ID, workout: workout, student: student,
                                                  status: "in_progress")
            PactStateContext.as(FactoryBot.create(:user, :personal, trainer: trainer))
          end
        end

        provider_state "a student is authenticated and attempts to react to student #{STUDENT_ID}'s " \
                       "completed check-in #{CHECK_IN_ID}" do
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
      end
    end
  end
end
