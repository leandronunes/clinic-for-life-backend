require "rails_helper"

RSpec.describe "Api::V1::Anamneses", type: :request do
  let(:trainer) { create(:trainer) }
  let(:personal) { create(:user, :personal, trainer: trainer) }
  let(:student) { create(:student, trainer: trainer) }
  let(:student_user) { create(:user, :student_account, student: student) }

  describe "GET .../anamnesis" do
    it "returns an empty anamnesis when none exists yet" do
      get "/api/v1/students/#{student.id}/anamnesis", headers: auth_headers(personal)
      expect(response).to have_http_status(:ok)
      expect(json_body["data"]).to have_key("objectives")
    end

    it "allows the student to read their own anamnesis" do
      get "/api/v1/students/#{student.id}/anamnesis", headers: auth_headers(student_user)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH .../anamnesis" do
    it "creates and updates fields plus external professionals" do
      params = {
        objectives: "Lose weight",
        notes: "Healthy",
        external_professionals: [{ name: "Dr. House", specialty: "Diagnostics" }]
      }
      patch "/api/v1/students/#{student.id}/anamnesis", params: params, headers: auth_headers(personal)

      expect(response).to have_http_status(:ok)
      expect(json_body["data"]["objectives"]).to eq("Lose weight")
      expect(json_body["data"]["external_professionals"].first["name"]).to eq("Dr. House")
    end

    it "replaces external professionals on subsequent updates" do
      anamnesis = create(:anamnesis, student: student)
      create(:external_professional, anamnesis: anamnesis, name: "Old")

      patch "/api/v1/students/#{student.id}/anamnesis",
            params: { external_professionals: [{ name: "New" }] }, headers: auth_headers(personal)

      names = json_body["data"]["external_professionals"].map { |p| p["name"] }
      expect(names).to eq(["New"])
    end

    it "forbids a student from editing the anamnesis" do
      patch "/api/v1/students/#{student.id}/anamnesis",
            params: { notes: "x" }, headers: auth_headers(student_user)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
