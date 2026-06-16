require "rails_helper"

RSpec.describe "Api::V1::Exams", type: :request do
  let(:trainer) { create(:trainer) }
  let(:personal) { create(:user, :personal, trainer: trainer) }
  let(:student) { create(:student, trainer: trainer) }
  let(:student_user) { create(:user, :student_account, student: student) }

  describe "GET .../exams" do
    it "lists exams" do
      create(:exam, student: student)
      get "/api/v1/students/#{student.id}/exams", headers: auth_headers(student_user)
      expect(json_body["data"].size).to eq(1)
    end
  end

  describe "POST .../exams" do
    it "creates an exam as personal" do
      params = { name: "Blood", file_url: "https://example.com/e.pdf", content_type: "application/pdf" }
      expect do
        post "/api/v1/students/#{student.id}/exams", params: params, headers: auth_headers(personal)
      end.to change(Exam, :count).by(1)
      expect(response).to have_http_status(:created)
    end

    it "forbids a student from uploading" do
      params = { name: "Blood", file_url: "https://example.com/e.pdf" }
      post "/api/v1/students/#{student.id}/exams", params: params, headers: auth_headers(student_user)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "DELETE .../exams/:id" do
    it "deletes an exam" do
      exam = create(:exam, student: student)
      expect do
        delete "/api/v1/students/#{student.id}/exams/#{exam.id}", headers: auth_headers(personal)
      end.to change(Exam, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end
  end
end
