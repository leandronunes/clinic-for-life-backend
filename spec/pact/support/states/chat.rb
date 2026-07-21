module PactStates
  module Chat
    STUDENT_ID = 2801
    OTHER_STUDENT_ID = 2802
    UNREAD_MESSAGE_ID = 2811
    MESSAGES_STUDENT_ID = 2803
    MESSAGE_ID_1 = 2821
    MESSAGE_ID_2 = 2822
    CREATE_STUDENT_ID = 2804
    READ_STUDENT_ID = 2805
    READ_MESSAGE_ID = 2831
    FORBIDDEN_STUDENT_ID = 2806

    def self.definitions
      proc do
        provider_state "a personal has 2 students, one with an unread message" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            student = FactoryBot.create(:student, id: STUDENT_ID, trainer: trainer, name: "Ana Silva")
            FactoryBot.create(:student, id: OTHER_STUDENT_ID, trainer: trainer, name: "Bruno Costa")
            FactoryBot.create(:chat_message, id: UNREAD_MESSAGE_ID, student: student, sender_role: "aluno",
                                              sender: FactoryBot.create(:user, :student_account, student: student),
                                              body: "Bom dia! 💪")
            PactStateContext.as(FactoryBot.create(:user, :personal, trainer: trainer))
          end
        end

        provider_state "a conversation with student_id #{MESSAGES_STUDENT_ID} has 2 messages" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            student = FactoryBot.create(:student, id: MESSAGES_STUDENT_ID, trainer: trainer)
            personal_user = FactoryBot.create(:user, :personal, trainer: trainer)
            FactoryBot.create(:chat_message, id: MESSAGE_ID_1, student: student, sender_role: "personal",
                                              sender: personal_user, body: "Oi! Como foi o treino?",
                                              created_at: 1.hour.ago)
            FactoryBot.create(:chat_message, id: MESSAGE_ID_2, student: student, sender_role: "aluno",
                                              sender: FactoryBot.create(:user, :student_account, student: student),
                                              body: "Foi ótimo! 😄", created_at: 30.minutes.ago)
            PactStateContext.as(personal_user)
          end
        end

        provider_state "a student_id #{CREATE_STUDENT_ID} exists and accepts new messages" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            student = FactoryBot.create(:student, id: CREATE_STUDENT_ID, trainer: trainer)
            PactStateContext.as(FactoryBot.create(:user, :personal, trainer: trainer))
          end
        end

        provider_state "a student_id #{READ_STUDENT_ID} exists to mark messages as read" do
          set_up do
            clean_database!
            trainer = FactoryBot.create(:trainer)
            student = FactoryBot.create(:student, id: READ_STUDENT_ID, trainer: trainer)
            FactoryBot.create(:chat_message, id: READ_MESSAGE_ID, student: student, sender_role: "aluno",
                                              sender: FactoryBot.create(:user, :student_account, student: student))
            PactStateContext.as(FactoryBot.create(:user, :personal, trainer: trainer))
          end
        end

        provider_state "a student_id #{FORBIDDEN_STUDENT_ID} does not belong to the current user" do
          set_up do
            clean_database!
            other_trainer = FactoryBot.create(:trainer)
            FactoryBot.create(:student, id: FORBIDDEN_STUDENT_ID, trainer: other_trainer)
            PactStateContext.as(FactoryBot.create(:user, :personal))
          end
        end
      end
    end
  end
end
