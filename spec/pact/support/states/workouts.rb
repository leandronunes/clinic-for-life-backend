module PactStates
  module Workouts
    STUDENT_ID = 701
    WORKOUT_ID = 801
    ARCHIVED_WORKOUT_ID = 802
    REORDER_WORKOUT_A = 803
    REORDER_WORKOUT_B = 804
    EXERCISE_ID = 901
    REORDER_EXERCISE_A = 902
    REORDER_EXERCISE_B = 903
    DELETE_EXERCISE_WORKOUT_ID = 805
    DELETE_EXERCISE_ID = 904
    STUDENT_LOAD_WORKOUT_ID = 806
    STUDENT_LOAD_EXERCISE_ID = 905

    def self.definitions
      proc do
        provider_state "a student with id #{STUDENT_ID} has workouts" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            student = FactoryBot.create(:student, id: STUDENT_ID, trainer: trainer)
            workout = FactoryBot.create(:workout, id: WORKOUT_ID, student: student)
            FactoryBot.create(:exercise, workout: workout)
            PactStateContext.as(FactoryBot.create(:user, :admin))
          end
        end

        provider_state "a student with id #{STUDENT_ID} exists for workout creation" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            FactoryBot.create(:student, id: STUDENT_ID, trainer: trainer)
            PactStateContext.as(FactoryBot.create(:user, :admin))
          end
        end

        provider_state "an active workout #{WORKOUT_ID} exists for student #{STUDENT_ID}" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            student = FactoryBot.create(:student, id: STUDENT_ID, trainer: trainer)
            FactoryBot.create(:workout, id: WORKOUT_ID, student: student, status: "active")
            PactStateContext.as(FactoryBot.create(:user, :admin))
          end
        end

        provider_state "an archived workout #{ARCHIVED_WORKOUT_ID} exists for student #{STUDENT_ID}" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            student = FactoryBot.create(:student, id: STUDENT_ID, trainer: trainer)
            FactoryBot.create(:workout, id: ARCHIVED_WORKOUT_ID, student: student, status: "archived",
                                        archived_at: Time.current, position: 1)
            PactStateContext.as(FactoryBot.create(:user, :admin))
          end
        end

        provider_state "student #{STUDENT_ID} has two active workouts to reorder" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            student = FactoryBot.create(:student, id: STUDENT_ID, trainer: trainer)
            FactoryBot.create(:workout, id: REORDER_WORKOUT_A, student: student, position: 1)
            FactoryBot.create(:workout, id: REORDER_WORKOUT_B, student: student, position: 2)
            PactStateContext.as(FactoryBot.create(:user, :admin))
          end
        end

        provider_state "workout #{WORKOUT_ID} exists for student #{STUDENT_ID} to add exercises to" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            student = FactoryBot.create(:student, id: STUDENT_ID, trainer: trainer)
            FactoryBot.create(:workout, id: WORKOUT_ID, student: student)
            PactStateContext.as(FactoryBot.create(:user, :admin))
          end
        end

        provider_state "workout #{WORKOUT_ID} for student #{STUDENT_ID} has exercise #{EXERCISE_ID}" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            student = FactoryBot.create(:student, id: STUDENT_ID, trainer: trainer)
            workout = FactoryBot.create(:workout, id: WORKOUT_ID, student: student)
            FactoryBot.create(:exercise, id: EXERCISE_ID, workout: workout)
            PactStateContext.as(FactoryBot.create(:user, :admin))
          end
        end

        provider_state "workout #{WORKOUT_ID} for student #{STUDENT_ID} has exercise #{EXERCISE_ID} with notes" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            student = FactoryBot.create(:student, id: STUDENT_ID, trainer: trainer)
            workout = FactoryBot.create(:workout, id: WORKOUT_ID, student: student)
            FactoryBot.create(:exercise, id: EXERCISE_ID, workout: workout, notes: "Manter postura")
            PactStateContext.as(FactoryBot.create(:user, :admin))
          end
        end

        provider_state "workout #{WORKOUT_ID} for student #{STUDENT_ID} has two exercises to reorder" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            student = FactoryBot.create(:student, id: STUDENT_ID, trainer: trainer)
            workout = FactoryBot.create(:workout, id: WORKOUT_ID, student: student)
            FactoryBot.create(:exercise, id: REORDER_EXERCISE_A, workout: workout, position: 1)
            FactoryBot.create(:exercise, id: REORDER_EXERCISE_B, workout: workout, position: 2)
            PactStateContext.as(FactoryBot.create(:user, :admin))
          end
        end

        provider_state "workout #{DELETE_EXERCISE_WORKOUT_ID} for student #{STUDENT_ID} has exercise " \
                       "#{DELETE_EXERCISE_ID} to delete" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            student = FactoryBot.create(:student, id: STUDENT_ID, trainer: trainer)
            workout = FactoryBot.create(:workout, id: DELETE_EXERCISE_WORKOUT_ID, student: student)
            FactoryBot.create(:exercise, id: DELETE_EXERCISE_ID, workout: workout)
            PactStateContext.as(FactoryBot.create(:user, :admin))
          end
        end

        provider_state "workout #{STUDENT_LOAD_WORKOUT_ID} for student #{STUDENT_ID} has exercise " \
                       "#{STUDENT_LOAD_EXERCISE_ID}, and that student is authenticated" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            student = FactoryBot.create(:student, id: STUDENT_ID, trainer: trainer)
            workout = FactoryBot.create(:workout, id: STUDENT_LOAD_WORKOUT_ID, student: student)
            FactoryBot.create(:exercise, id: STUDENT_LOAD_EXERCISE_ID, workout: workout, load_kg: 20)
            student_user = FactoryBot.create(:user, :student_account, student: student)
            PactStateContext.as(student_user)
          end
        end

        provider_state "a student with id #{STUDENT_ID} exists and a non-admin student is authenticated" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            FactoryBot.create(:student, id: STUDENT_ID, trainer: trainer)
            PactStateContext.as(FactoryBot.create(:user, :student_account))
          end
        end
      end
    end
  end
end
