module PactStates
  module Evolution
    STUDENT_ID = 1401
    MEASUREMENT_ID = 1501
    PHOTO_ID = 1601

    def self.definitions
      proc do
        provider_state "a student with id #{STUDENT_ID} has measurements and photos" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            student = FactoryBot.create(:student, id: STUDENT_ID, trainer: trainer)
            FactoryBot.create(:bioimpedance_measurement, id: MEASUREMENT_ID, student: student)
            PactStateContext.as(FactoryBot.create(:user, :admin))
          end
        end

        provider_state "a student with id #{STUDENT_ID} has a measurement with no photo yet" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            student = FactoryBot.create(:student, id: STUDENT_ID, trainer: trainer)
            FactoryBot.create(:bioimpedance_measurement, id: MEASUREMENT_ID, student: student)
            PactStateContext.as(FactoryBot.create(:user, :admin))
          end
        end

        provider_state "a student with id #{STUDENT_ID} has an evolution photo #{PHOTO_ID}" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            student = FactoryBot.create(:student, id: STUDENT_ID, trainer: trainer)
            FactoryBot.create(:evolution_photo, id: PHOTO_ID, student: student,
                                                bioimpedance_measurement: nil, taken_on: Date.current)
            PactStateContext.as(FactoryBot.create(:user, :admin))
          end
        end

        provider_state "a student with id #{STUDENT_ID} has a measurement that already has a photo" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            student = FactoryBot.create(:student, id: STUDENT_ID, trainer: trainer)
            measurement = FactoryBot.create(:bioimpedance_measurement, id: MEASUREMENT_ID, student: student)
            FactoryBot.create(:evolution_photo, student: student, bioimpedance_measurement: measurement)
            PactStateContext.as(FactoryBot.create(:user, :admin))
          end
        end
      end
    end
  end
end
