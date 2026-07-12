require "rails_helper"

RSpec.describe "Api::V1::Feedbacks", type: :request do
  let(:trainer) { create(:trainer) }
  let(:personal) { create(:user, :personal, trainer: trainer) }
  let(:student) { create(:student, trainer: trainer) }
  let(:student_user) { create(:user, :student_account, student: student) }
  let(:admin) { create(:user, :admin) }

  describe "GET /api/v1/students/:student_id/feedbacks" do
    it "is visible to the student themselves" do
      create(:feedback, student: student, author: personal)
      get "/api/v1/students/#{student.id}/feedbacks", headers: auth_headers(student_user)

      expect(response).to have_http_status(:ok)
      expect(json_body["data"].size).to eq(1)
    end

    it "is visible to the student's personal" do
      create(:feedback, student: student, author: personal)
      get "/api/v1/students/#{student.id}/feedbacks", headers: auth_headers(personal)

      expect(response).to have_http_status(:ok)
    end

    it "forbids a personal outside the student's portfolio" do
      other_personal = create(:user, :personal)
      get "/api/v1/students/#{student.id}/feedbacks", headers: auth_headers(other_personal)

      expect(response).to have_http_status(:forbidden)
    end

    it "orders results most recent first" do
      older = create(:feedback, student: student, author: personal, created_at: 2.days.ago)
      newer = create(:feedback, student: student, author: personal, created_at: 1.hour.ago)

      get "/api/v1/students/#{student.id}/feedbacks", headers: auth_headers(student_user)

      ids = json_body["data"].map { |f| f["id"] }
      expect(ids).to eq([ newer.id.to_s, older.id.to_s ])
    end
  end

  describe "POST /api/v1/students/:student_id/feedbacks" do
    let(:valid_params) { { kind: "elogio", message: "Muito bem no treino de hoje!" } }

    it "creates a feedback note as the current user" do
      post "/api/v1/students/#{student.id}/feedbacks", params: valid_params, headers: auth_headers(personal)

      expect(response).to have_http_status(:created)
      expect(json_body["data"]["author_name"]).to eq(personal.name)
      expect(json_body["data"]["kind"]).to eq("elogio")
    end

    it "allows an admin to send feedback" do
      post "/api/v1/students/#{student.id}/feedbacks", params: valid_params, headers: auth_headers(admin)
      expect(response).to have_http_status(:created)
    end

    it "forbids a student from sending feedback" do
      post "/api/v1/students/#{student.id}/feedbacks", params: valid_params, headers: auth_headers(student_user)
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 422 for an invalid kind" do
      post "/api/v1/students/#{student.id}/feedbacks", params: valid_params.merge(kind: "bogus"),
                                                          headers: auth_headers(personal)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 422 for a blank message" do
      post "/api/v1/students/#{student.id}/feedbacks", params: valid_params.merge(message: ""),
                                                          headers: auth_headers(personal)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "does not enqueue a push notification when the student has no linked user" do
      expect do
        post "/api/v1/students/#{student.id}/feedbacks", params: valid_params, headers: auth_headers(personal)
      end.not_to have_enqueued_job(PushNotificationJob)
    end

    it "enqueues a push notification to the student with a kind-specific title" do
      student_user
      expect do
        post "/api/v1/students/#{student.id}/feedbacks", params: valid_params, headers: auth_headers(personal)
      end.to have_enqueued_job(PushNotificationJob).with(
        student_user.id,
        hash_including(title: "Elogio do seu Personal", url: "/aluno/assiduidade")
      )
    end
  end
end
