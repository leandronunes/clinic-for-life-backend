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
      expect(labels).to include("Alunos Ativos", "Personais", "Parceiros")
    end

    it "includes a numeric delta field in every card" do
      get "/api/v1/dashboard/kpis", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      json_body["data"].each do |card|
        expect(card).to have_key("delta")
        expect(card["delta"]).to be_a(Numeric)
      end
    end

    it "accepts a range param without error" do
      get "/api/v1/dashboard/kpis", params: { range: "week" }, headers: auth_headers(admin)
      expect(response).to have_http_status(:ok)
      expect(json_body["data"].length).to eq(5)
    end

    it "scopes counts to the personal's own portfolio" do
      own = create(:student, trainer: trainer, status: "active")
      create(:student, status: "active") # another trainer
      create(:workout, student: own, status: "active")

      get "/api/v1/dashboard/kpis", headers: auth_headers(personal)
      cards = json_body["data"].index_by { |c| c["label"] }
      expect(cards["Alunos Ativos"]["value"]).to eq(1)
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

    it "accepts a range param and returns a series" do
      get "/api/v1/dashboard/activity", params: { range: "week" }, headers: auth_headers(admin)
      expect(response).to have_http_status(:ok)
      expect(json_body["data"]).to all(include("label", "workouts", "assessments"))
      expect(json_body["data"].length).to eq(8) # 7 days ago..today = 8 dates
    end

    it "defaults to 30 days when no params are given" do
      get "/api/v1/dashboard/activity", headers: auth_headers(admin)
      expect(response).to have_http_status(:ok)
      expect(json_body["data"].length).to eq(31) # 30 days ago..today = 31 dates
    end
  end

  describe "GET /api/v1/dashboard/attendance" do
    it "returns the attendance summary" do
      student = create(:student, status: "active")
      workout = create(:workout, student: student)
      create(:workout_check_in, :completed, workout: workout, student: student)
      create(:workout_check_in, workout: create(:workout, student: student), student: student)

      get "/api/v1/dashboard/attendance", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      data = json_body["data"]
      expect(data["total_check_ins"]).to eq(2)
      expect(data["completed_check_ins"]).to eq(1)
      expect(data["students_with_check_in"]).to eq(1)
    end

    it "excludes check-ins older than the selected range" do
      student = create(:student, status: "active")
      workout = create(:workout, student: student)
      create(:workout_check_in, :completed, workout: workout, student: student, created_at: 60.days.ago)

      get "/api/v1/dashboard/attendance", params: { range: "week" }, headers: auth_headers(admin)

      expect(json_body["data"]["total_check_ins"]).to eq(0)
    end

    it "scopes counts to the personal's own portfolio" do
      own = create(:student, trainer: trainer, status: "active")
      other = create(:student, status: "active")
      create(:workout_check_in, :completed, workout: create(:workout, student: own), student: own)
      create(:workout_check_in, :completed, workout: create(:workout, student: other), student: other)

      get "/api/v1/dashboard/attendance", headers: auth_headers(personal)

      expect(json_body["data"]["total_check_ins"]).to eq(1)
    end

    it "forbids a student" do
      student_user = create(:user, :student_account)
      get "/api/v1/dashboard/attendance", headers: auth_headers(student_user)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
