module PactStates
  module CheckIns
    STUDENT_ID = 2301
    WORKOUT_ID = 2311
    EXERCISE_ID = 2321
    OTHER_EXERCISE_ID = 2322
    CHECK_IN_ID = 2331
    HISTORY_WORKOUT_ID = 2341
    HISTORY_CHECK_IN_ID = 2351
    VIEW_WORKOUT_ID = 2342
    VIEW_CHECK_IN_ID = 2352
    DELETE_WORKOUT_ID = 2343
    DELETE_CHECK_IN_ID = 2353
    TODAY_WORKOUT_ID = 2344
    TODAY_CHECK_IN_ID = 2354
    CLAIM_WORKOUT_ID = 2345
    CLAIM_CHECK_IN_ID = 2355
    PSE_WORKOUT_ID = 2346
    PSE_CHECK_IN_ID = 2356

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

        # Two exercises on the workout, so marking #EXERCISE_ID alone leaves
        # the check-in genuinely in progress (auto-finish only kicks in once
        # every exercise on the workout is checked) — a single-exercise
        # workout would make the "mark one exercise" interaction indistinguishable
        # from "finish the check-in".
        provider_state "student #{STUDENT_ID} has an in-progress check-in #{CHECK_IN_ID} on workout " \
                       "#{WORKOUT_ID} with exercise #{EXERCISE_ID} pending" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            student = FactoryBot.create(:student, id: STUDENT_ID, trainer: trainer)
            workout = FactoryBot.create(:workout, id: WORKOUT_ID, student: student, status: "active")
            FactoryBot.create(:exercise, id: EXERCISE_ID, workout: workout)
            FactoryBot.create(:exercise, id: OTHER_EXERCISE_ID, workout: workout)
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

        provider_state "student #{STUDENT_ID} has a completed check-in #{VIEW_CHECK_IN_ID} on " \
                       "workout #{VIEW_WORKOUT_ID} to mark as viewed" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            student = FactoryBot.create(:student, id: STUDENT_ID, trainer: trainer)
            workout = FactoryBot.create(:workout, id: VIEW_WORKOUT_ID, student: student, title: "Treino A")
            FactoryBot.create(:workout_check_in, id: VIEW_CHECK_IN_ID, workout: workout, student: student,
                                                  status: "completed", completed_at: Time.current)
            PactStateContext.as(FactoryBot.create(:user, :personal, trainer: trainer))
          end
        end

        provider_state "student #{STUDENT_ID} has a completed check-in #{DELETE_CHECK_IN_ID} on " \
                       "workout #{DELETE_WORKOUT_ID} to remove" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            student = FactoryBot.create(:student, id: STUDENT_ID, trainer: trainer)
            workout = FactoryBot.create(:workout, id: DELETE_WORKOUT_ID, student: student, title: "Treino A")
            FactoryBot.create(:workout_check_in, id: DELETE_CHECK_IN_ID, workout: workout, student: student,
                                                  status: "completed", completed_at: Time.current)
            student_user = FactoryBot.create(:user, :student_account, student: student)
            PactStateContext.as(student_user)
          end
        end

        provider_state "student #{STUDENT_ID} already completed workout #{TODAY_WORKOUT_ID} " \
                       "today (check-in #{TODAY_CHECK_IN_ID})" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            student = FactoryBot.create(:student, id: STUDENT_ID, trainer: trainer)
            workout = FactoryBot.create(:workout, id: TODAY_WORKOUT_ID, student: student, title: "Treino A")
            FactoryBot.create(:workout_check_in, id: TODAY_CHECK_IN_ID, workout: workout, student: student,
                                                  status: "completed", completed_at: Time.current)
            PactStateContext.as(FactoryBot.create(:user, :admin))
          end
        end

        provider_state "student #{STUDENT_ID} has a completed check-in #{CLAIM_CHECK_IN_ID} on " \
                       "workout #{CLAIM_WORKOUT_ID} performed by the aluno, to claim" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            student = FactoryBot.create(:student, id: STUDENT_ID, trainer: trainer)
            workout = FactoryBot.create(:workout, id: CLAIM_WORKOUT_ID, student: student, title: "Treino A")
            FactoryBot.create(:workout_check_in, id: CLAIM_CHECK_IN_ID, workout: workout, student: student,
                                                  status: "completed", completed_at: Time.current,
                                                  performed_by: "aluno")
            PactStateContext.as(FactoryBot.create(:user, :personal, trainer: trainer))
          end
        end

        provider_state "student #{STUDENT_ID} has a completed check-in #{PSE_CHECK_IN_ID} on " \
                       "workout #{PSE_WORKOUT_ID} with no PSE recorded yet" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            student = FactoryBot.create(:student, id: STUDENT_ID, trainer: trainer)
            workout = FactoryBot.create(:workout, id: PSE_WORKOUT_ID, student: student, title: "Treino A")
            FactoryBot.create(:workout_check_in, id: PSE_CHECK_IN_ID, workout: workout, student: student,
                                                  status: "completed", completed_at: Time.current)
            student_user = FactoryBot.create(:user, :student_account, student: student)
            PactStateContext.as(student_user)
          end
        end
      end
    end
  end
end
