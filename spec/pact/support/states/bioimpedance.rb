module PactStates
  module Bioimpedance
    STUDENT_ID = 1701
    MEASUREMENT_ID = 1801
    DELETE_MEASUREMENT_ID = 1802

    def self.definitions
      proc do
        provider_state "a student with id #{STUDENT_ID} has bioimpedance measurements" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            student = FactoryBot.create(:student, id: STUDENT_ID, trainer: trainer)
            FactoryBot.create(:bioimpedance_measurement, id: MEASUREMENT_ID, student: student,
                                                          measured_on: Date.new(2025, 1, 1))
            PactStateContext.as(FactoryBot.create(:user, :admin))
          end
        end

        provider_state "a student with id #{STUDENT_ID} exists for a new measurement" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            FactoryBot.create(:student, id: STUDENT_ID, trainer: trainer)
            PactStateContext.as(FactoryBot.create(:user, :admin))
          end
        end

        provider_state "a student with id #{STUDENT_ID} has a measurement #{DELETE_MEASUREMENT_ID} to delete" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            student = FactoryBot.create(:student, id: STUDENT_ID, trainer: trainer)
            FactoryBot.create(:bioimpedance_measurement, id: DELETE_MEASUREMENT_ID, student: student)
            PactStateContext.as(FactoryBot.create(:user, :admin))
          end
        end

        provider_state "a student with id #{STUDENT_ID} exists for CSV import" do
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
