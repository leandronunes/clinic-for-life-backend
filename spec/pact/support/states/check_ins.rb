module PactStates
  module CheckIns
    STUDENT_ID = 2301
    WORKOUT_ID = 2311
    EXERCISE_ID = 2321
    CHECK_IN_ID = 2331
    HISTORY_WORKOUT_ID = 2341
    HISTORY_CHECK_IN_ID = 2351

    def self.definitions
      proc do
        provider_state "a student with id #{STUDENT_ID} has an active workout #{WORKOUT_ID} " \
                       "with no check-in in progress" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            student = FactoryBot.create(:student, id: STUDENT_ID, trainer: trainer)
            workout = FactoryBot.create(:workout, id: WORKOUT_ID, student: student, status: "active")
            FactoryBot.create(:exercise, id: EXERCISE_ID, workout: workout)
            PactStateContext.as(FactoryBot.create(:user, :admin))
          end
        end

        provider_state "student #{STUDENT_ID} has an in-progress check-in #{CHECK_IN_ID} on workout " \
                       "#{WORKOUT_ID} with exercise #{EXERCISE_ID} pending" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            student = FactoryBot.create(:student, id: STUDENT_ID, trainer: trainer)
            workout = FactoryBot.create(:workout, id: WORKOUT_ID, student: student, status: "active")
            FactoryBot.create(:exercise, id: EXERCISE_ID, workout: workout)
            FactoryBot.create(:workout_check_in, id: CHECK_IN_ID, workout: workout, student: student,
                                                  status: "in_progress")
            PactStateContext.as(FactoryBot.create(:user, :admin))
          end
        end

        provider_state "student #{STUDENT_ID} has a completed check-in #{HISTORY_CHECK_IN_ID} on " \
                       "workout #{HISTORY_WORKOUT_ID} in their history" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            student = FactoryBot.create(:student, id: STUDENT_ID, trainer: trainer)
            workout = FactoryBot.create(:workout, id: HISTORY_WORKOUT_ID, student: student, title: "Treino A")
            FactoryBot.create(:workout_check_in, id: HISTORY_CHECK_IN_ID, workout: workout, student: student,
                                                  status: "completed", completed_at: Time.current)
            PactStateContext.as(FactoryBot.create(:user, :admin))
          end
        end
      end
    end
  end
end
