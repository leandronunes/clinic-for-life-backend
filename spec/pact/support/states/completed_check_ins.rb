module PactStates
  module CompletedCheckIns
    STUDENT_ID = 2601
    WORKOUT_ID = 2611
    CHECK_IN_ID = 2621

    def self.definitions
      proc do
        provider_state "a personal has a completed check-in #{CHECK_IN_ID} for student " \
                       "#{STUDENT_ID} in their portfolio" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            student = FactoryBot.create(:student, id: STUDENT_ID, trainer: trainer)
            workout = FactoryBot.create(:workout, id: WORKOUT_ID, student: student, title: "Treino A")
            FactoryBot.create(:workout_check_in, id: CHECK_IN_ID, workout: workout, student: student,
                                                  status: "completed", completed_at: Time.current,
                                                  student_confirmed_at: Time.current)
            PactStateContext.as(FactoryBot.create(:user, :personal, trainer: trainer))
          end
        end

        provider_state "a student is authenticated and attempts to list completed check-ins" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            student = FactoryBot.create(:student, trainer: trainer)
            PactStateContext.as(FactoryBot.create(:user, :student_account, student: student))
          end
        end
      end
    end
  end
end
