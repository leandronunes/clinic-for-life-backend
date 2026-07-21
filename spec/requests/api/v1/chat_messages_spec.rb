require "rails_helper"

RSpec.describe "Api::V1::ChatMessages", type: :request do
  let(:trainer) { create(:trainer) }
  let(:personal) { create(:user, :personal, trainer: trainer) }
  let(:student) { create(:student, trainer: trainer) }
  let(:student_user) { create(:user, :student_account, student: student) }
  let(:admin) { create(:user, :admin) }
  let(:other_trainer) { create(:trainer) }
  let(:other_personal) { create(:user, :personal, trainer: other_trainer) }
  let(:base_path) { "/api/v1/chat/conversations/#{student.id}" }

  describe "GET /api/v1/chat/conversations/:student_id/messages" do
    it "returns the conversation's messages in chronological order" do
      second = create(:chat_message, :from_personal, student: student, created_at: 1.hour.ago)
      first = create(:chat_message, :from_aluno, student: student, created_at: 2.hours.ago)

      get "#{base_path}/messages", headers: auth_headers(personal)

      expect(response).to have_http_status(:ok)
      expect(json_body["data"].map { |m| m["id"] }).to eq([ first.id.to_s, second.id.to_s ])
    end

    it "lets the aluno themselves read their own conversation" do
      create(:chat_message, :from_personal, student: student)

      get "#{base_path}/messages", headers: auth_headers(student_user)

      expect(response).to have_http_status(:ok)
      expect(json_body["data"].size).to eq(1)
    end

    it "forbids a personal from reading a conversation outside their portfolio" do
      get "#{base_path}/messages", headers: auth_headers(other_personal)
      expect(response).to have_http_status(:forbidden)
    end

    it "forbids a student from reading another student's conversation" do
      other_student_user = create(:user, :student_account)
      get "#{base_path}/messages", headers: auth_headers(other_student_user)
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 404 for a student_id that does not exist" do
      get "/api/v1/chat/conversations/999999/messages", headers: auth_headers(admin)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/chat/conversations/:student_id/messages" do
    it "creates a message as the personal, deriving sender from the current user" do
      post "#{base_path}/messages", params: { body: "Bom treino hoje!" }, headers: auth_headers(personal)

      expect(response).to have_http_status(:created)
      expect(json_body["data"]["body"]).to eq("Bom treino hoje!")
      expect(json_body["data"]["sender_role"]).to eq("personal")
      expect(json_body["data"]["sender_id"]).to eq(personal.id.to_s)
      expect(json_body["data"]["sender_name"]).to eq(personal.name)
      expect(json_body["data"]["read_at"]).to be_nil
    end

    it "creates a message as the aluno when sent by the student" do
      post "#{base_path}/messages", params: { body: "Oi!" }, headers: auth_headers(student_user)

      expect(response).to have_http_status(:created)
      expect(json_body["data"]["sender_role"]).to eq("aluno")
      expect(json_body["data"]["sender_id"]).to eq(student_user.id.to_s)
    end

    it "ignores a client-supplied sender_role, deriving it from the current user instead" do
      post "#{base_path}/messages",
           params: { body: "Tentando forjar", sender_role: "personal" },
           headers: auth_headers(student_user)

      expect(json_body["data"]["sender_role"]).to eq("aluno")
    end

    it "rejects an empty body" do
      post "#{base_path}/messages", params: { body: "" }, headers: auth_headers(personal)
      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body["error"]).to be_present
    end

    it "rejects a body that is only whitespace" do
      post "#{base_path}/messages", params: { body: "   " }, headers: auth_headers(personal)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rejects a body over 4000 characters" do
      post "#{base_path}/messages", params: { body: "a" * 4001 }, headers: auth_headers(personal)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "records an audit log" do
      expect do
        post "#{base_path}/messages", params: { body: "Oi!" }, headers: auth_headers(personal)
      end.to change(AuditLog, :count).by(1)
    end

    it "forbids a personal from messaging a student outside their portfolio" do
      post "#{base_path}/messages", params: { body: "Oi!" }, headers: auth_headers(other_personal)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/v1/chat/conversations/:student_id/read" do
    it "marks only messages from the other side as read" do
      from_aluno = create(:chat_message, :from_aluno, student: student)
      from_personal = create(:chat_message, :from_personal, student: student)

      post "#{base_path}/read", headers: auth_headers(personal)

      expect(response).to have_http_status(:ok)
      expect(json_body["data"]["read"]).to eq(1)
      expect(from_aluno.reload.read_at).to be_present
      expect(from_personal.reload.read_at).to be_nil
    end

    it "returns read: 0 and 200 when there is nothing pending" do
      post "#{base_path}/read", headers: auth_headers(personal)

      expect(response).to have_http_status(:ok)
      expect(json_body["data"]["read"]).to eq(0)
    end

    it "is idempotent — a second call reports 0 newly read" do
      create(:chat_message, :from_aluno, student: student)

      post "#{base_path}/read", headers: auth_headers(personal)
      post "#{base_path}/read", headers: auth_headers(personal)

      expect(json_body["data"]["read"]).to eq(0)
    end

    it "forbids a personal from marking a conversation outside their portfolio as read" do
      post "#{base_path}/read", headers: auth_headers(other_personal)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
