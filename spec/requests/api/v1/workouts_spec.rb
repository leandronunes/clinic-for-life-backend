require "rails_helper"

RSpec.describe "Api::V1::Workouts", type: :request do
  let(:trainer) { create(:trainer) }
  let(:personal) { create(:user, :personal, trainer: trainer) }
  let(:student) { create(:student, trainer: trainer) }
  let(:student_user) { create(:user, :student_account, student: student) }

  describe "GET /api/v1/students/:student_id/workouts" do
    it "lists workouts for the student" do
      create(:workout, student: student, status: "active")
      create(:workout, :archived, student: student)
      get "/api/v1/students/#{student.id}/workouts", headers: auth_headers(personal)
      expect(json_body["data"].size).to eq(2)
    end

    it "filters by status" do
      create(:workout, student: student, status: "active")
      create(:workout, :archived, student: student)
      get "/api/v1/students/#{student.id}/workouts", params: { status: "active" },
          headers: auth_headers(personal)
      expect(json_body["data"].map { |w| w["status"] }).to all(eq("active"))
    end
  end

  describe "POST /api/v1/students/:student_id/workouts" do
    it "creates a workout with nested exercises" do
      params = {
        title: "Push Day", focus: "Push", status: "active",
        exercises: [ { name: "Bench Press", sets: 4, reps: "8-10", rest_seconds: 90 } ]
      }
      expect do
        post "/api/v1/students/#{student.id}/workouts", params: params, headers: auth_headers(personal)
      end.to change(Workout, :count).by(1).and change(Exercise, :count).by(1)
      expect(response).to have_http_status(:created)
    end

    it "archives previously active workouts when activating a new one" do
      old = create(:workout, student: student, status: "active")
      post "/api/v1/students/#{student.id}/workouts",
           params: { title: "New Active", status: "active" }, headers: auth_headers(personal)

      expect(old.reload.status).to eq("archived")
      expect(student.workouts.active.count).to eq(1)
    end

    it "forbids a student from creating workouts" do
      post "/api/v1/students/#{student.id}/workouts",
           params: { title: "X" }, headers: auth_headers(student_user)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "PATCH /api/v1/students/:student_id/workouts/:id" do
    it "archives others when an existing workout is set to active" do
      active = create(:workout, student: student, status: "active")
      archived = create(:workout, :archived, student: student)

      patch "/api/v1/students/#{student.id}/workouts/#{archived.id}",
            params: { status: "active" }, headers: auth_headers(personal)

      expect(archived.reload.status).to eq("active")
      expect(active.reload.status).to eq("archived")
    end
  end

  describe "POST /api/v1/students/:student_id/workouts/:id/archive" do
    it "archives the workout" do
      workout = create(:workout, student: student, status: "active")
      post "/api/v1/students/#{student.id}/workouts/#{workout.id}/archive",
           headers: auth_headers(personal)
      expect(workout.reload.status).to eq("archived")
    end
  end
end
