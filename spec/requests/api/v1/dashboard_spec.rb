require "rails_helper"

RSpec.describe "Api::V1::Dashboard", type: :request do
  let(:trainer) { create(:trainer) }
  let(:admin) { create(:user, :admin) }
  let(:personal) { create(:user, :personal, trainer: trainer) }

  describe "GET /api/v1/dashboard/kpis" do
    it "returns the KPI cards for an admin" do
      create_list(:student, 2)
      get "/api/v1/dashboard/kpis", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      labels = json_body["data"].map { |c| c["label"] }
      expect(labels).to include("Active Students", "Trainers", "Partners")
    end

    it "scopes counts to the personal's own portfolio" do
      own = create(:student, trainer: trainer, status: "active")
      create(:student, status: "active") # another trainer
      create(:workout, student: own, status: "active")

      get "/api/v1/dashboard/kpis", headers: auth_headers(personal)
      cards = json_body["data"].index_by { |c| c["label"] }
      expect(cards["Active Students"]["value"]).to eq(1)
    end

    it "forbids a student" do
      student_user = create(:user, :student_account)
      get "/api/v1/dashboard/kpis", headers: auth_headers(student_user)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /api/v1/dashboard/activity" do
    it "returns a daily activity series" do
      get "/api/v1/dashboard/activity", params: { days: 5 }, headers: auth_headers(admin)
      expect(response).to have_http_status(:ok)
      expect(json_body["data"]).to all(include("label", "workouts", "assessments"))
    end
  end
end
