require "rails_helper"

RSpec.describe "Api::V1::ChatConversations", type: :request do
  let(:trainer) { create(:trainer) }
  let(:personal) { create(:user, :personal, trainer: trainer) }
  let(:other_trainer) { create(:trainer) }
  let(:student) { create(:student, trainer: trainer) }
  let(:student_user) { create(:user, :student_account, student: student) }
  let(:other_student) { create(:student, trainer: other_trainer) }
  let(:admin) { create(:user, :admin) }

  describe "GET /api/v1/chat/conversations" do
    it "lets an aluno see only their own conversation" do
      create(:chat_message, :from_personal, student: student)
      create(:chat_message, :from_personal, student: other_student)

      get "/api/v1/chat/conversations", headers: auth_headers(student_user)

      expect(response).to have_http_status(:ok)
      expect(json_body["data"].map { |c| c["student_id"] }).to contain_exactly(student.id.to_s)
    end

    it "lets a personal see only their own students, including one with no messages yet" do
      other_student_of_same_trainer = create(:student, trainer: trainer)
      create(:chat_message, :from_aluno, student: student)
      create(:chat_message, :from_personal, student: other_student)

      get "/api/v1/chat/conversations", headers: auth_headers(personal)

      ids = json_body["data"].map { |c| c["student_id"] }
      expect(ids).to contain_exactly(student.id.to_s, other_student_of_same_trainer.id.to_s)
    end

    it "lets an admin see every conversation" do
      create(:chat_message, :from_aluno, student: student)
      create(:chat_message, :from_personal, student: other_student)

      get "/api/v1/chat/conversations", headers: auth_headers(admin)

      ids = json_body["data"].map { |c| c["student_id"] }
      expect(ids).to include(student.id.to_s, other_student.id.to_s)
    end

    it "includes a null last_message and zero unread_count for a student with no messages" do
      student # force creation — this test has no chat_message to do it implicitly

      get "/api/v1/chat/conversations", headers: auth_headers(personal)

      conv = json_body["data"].find { |c| c["student_id"] == student.id.to_s }
      expect(conv["last_message"]).to be_nil
      expect(conv["unread_count"]).to eq(0)
    end

    it "counts only unread messages sent by the other side" do
      create(:chat_message, :from_aluno, student: student, read_at: nil)
      create(:chat_message, :from_personal, student: student, read_at: nil)
      create(:chat_message, :from_aluno, :read, student: student)

      get "/api/v1/chat/conversations", headers: auth_headers(personal)

      conv = json_body["data"].find { |c| c["student_id"] == student.id.to_s }
      expect(conv["unread_count"]).to eq(1)
    end

    it "orders conversations by the most recent message first" do
      older_student = create(:student, trainer: trainer)
      create(:chat_message, :from_aluno, student: older_student, created_at: 2.days.ago)
      create(:chat_message, :from_aluno, student: student, created_at: 1.hour.ago)

      get "/api/v1/chat/conversations", headers: auth_headers(personal)

      ids = json_body["data"].map { |c| c["student_id"] }
      expect(ids.index(student.id.to_s)).to be < ids.index(older_student.id.to_s)
    end

    it "includes the sender_name on the last_message" do
      create(:chat_message, :from_personal, student: student, sender: personal, body: "Oi!")

      get "/api/v1/chat/conversations", headers: auth_headers(personal)

      conv = json_body["data"].find { |c| c["student_id"] == student.id.to_s }
      expect(conv["last_message"]["sender_name"]).to eq(personal.name)
      expect(conv["last_message"]["body"]).to eq("Oi!")
    end

    it "rejects requests without a token" do
      get "/api/v1/chat/conversations"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
