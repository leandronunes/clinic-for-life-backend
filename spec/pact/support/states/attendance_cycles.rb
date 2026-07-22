module PactStates
  module AttendanceCycles
    RENEW_ID = 2401
    RENEW_NO_CONTRACT_ID = 2402
    RENEW_FORBIDDEN_ID = 2403
    HISTORY_ID = 2411
    HISTORY_EMPTY_ID = 2412
    HISTORY_FORBIDDEN_ID = 2413

    def self.definitions
      proc do
        provider_state "a student with id #{RENEW_ID} has a contract to renew" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            FactoryBot.create(:student, id: RENEW_ID, trainer: trainer,
                                        contracted_workouts_per_cycle: 8, cycle_started_at: 2.months.ago)
            PactStateContext.as(FactoryBot.create(:user, :admin, organization: trainer.organization))
          end
        end

        provider_state "a student with id #{RENEW_NO_CONTRACT_ID} has no contracted quota" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            FactoryBot.create(:student, id: RENEW_NO_CONTRACT_ID, trainer: trainer,
                                        contracted_workouts_per_cycle: nil)
            PactStateContext.as(FactoryBot.create(:user, :admin, organization: trainer.organization))
          end
        end

        provider_state "a student with id #{RENEW_FORBIDDEN_ID} belongs to another trainer and has a contract" do
          set_up do
            clean_database!
            other_trainer = FactoryBot.create(:trainer)
            FactoryBot.create(:student, id: RENEW_FORBIDDEN_ID, trainer: other_trainer,
                                        contracted_workouts_per_cycle: 8)
            requesting_trainer = FactoryBot.create(:trainer)
            PactStateContext.as(FactoryBot.create(:user, :personal, trainer: requesting_trainer))
          end
        end

        provider_state "a student with id #{HISTORY_ID} has a closed attendance cycle" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            student = FactoryBot.create(:student, id: HISTORY_ID, trainer: trainer)
            workout = FactoryBot.create(:workout, student: student)
            FactoryBot.create(:attendance_cycle, student: student, contracted_workouts_per_cycle: 8,
                                                  started_at: 2.months.ago, ended_at: 1.month.ago)
            FactoryBot.create(:workout_check_in, :completed, workout: workout, student: student,
                                                  completed_at: 6.weeks.ago)
            PactStateContext.as(FactoryBot.create(:user, :admin, organization: trainer.organization))
          end
        end

        provider_state "a student with id #{HISTORY_EMPTY_ID} has no closed attendance cycles" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            FactoryBot.create(:student, id: HISTORY_EMPTY_ID, trainer: trainer)
            PactStateContext.as(FactoryBot.create(:user, :admin, organization: trainer.organization))
          end
        end

        provider_state "a student with id #{HISTORY_FORBIDDEN_ID} belongs to another trainer" do
          set_up do
            clean_database!
            other_trainer = FactoryBot.create(:trainer)
            FactoryBot.create(:student, id: HISTORY_FORBIDDEN_ID, trainer: other_trainer)
            requesting_trainer = FactoryBot.create(:trainer)
            PactStateContext.as(FactoryBot.create(:user, :personal, trainer: requesting_trainer))
          end
        end
      end
    end
  end
end
