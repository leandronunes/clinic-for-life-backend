require "rails_helper"

RSpec.describe "Api::V1::StructuralAssessments", type: :request do
  let(:trainer) { create(:trainer) }
  let(:personal) { create(:user, :personal, trainer: trainer) }
  let(:student) { create(:student, trainer: trainer) }

  describe "GET .../structural_assessment" do
    it "returns a default assessment with all items false" do
      get "/api/v1/students/#{student.id}/structural_assessment", headers: auth_headers(personal)
      expect(response).to have_http_status(:ok)
      expect(json_body["data"]["scoliosis"]).to be(false)
    end
  end

  describe "PATCH .../structural_assessment" do
    it "persists boolean findings" do
      patch "/api/v1/students/#{student.id}/structural_assessment",
            params: { scoliosis: true, knee_valgus: true }, headers: auth_headers(personal)
      expect(response).to have_http_status(:ok)
      expect(json_body["data"]["scoliosis"]).to be(true)
      expect(student.reload.structural_assessment.knee_valgus).to be(true)
    end
  end
end
