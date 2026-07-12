require "rails_helper"

RSpec.describe "Api::V1::CheckIns", type: :request do
  let(:trainer) { create(:trainer) }
  let(:personal) { create(:user, :personal, trainer: trainer) }
  let(:student) { create(:student, trainer: trainer) }
  let(:student_user) { create(:user, :student_account, student: student) }
  let(:admin) { create(:user, :admin) }

  describe "GET /api/v1/students/:student_id/check_ins" do
    it "lists the student's check-ins across every workout, most recent first" do
      workout_a = create(:workout, student: student)
      workout_b = create(:workout, student: student)
      older = create(:workout_check_in, :completed, workout: workout_a, student: student,
                     created_at: 2.days.ago)
      newer = create(:workout_check_in, :completed, workout: workout_b, student: student,
                     created_at: 1.hour.ago)

      get "/api/v1/students/#{student.id}/check_ins", headers: auth_headers(student_user)

      ids = json_body["data"].map { |c| c["id"] }
      expect(ids).to eq([ newer.id.to_s, older.id.to_s ])
    end

    it "includes the workout title even after the workout is later archived" do
      workout = create(:workout, student: student, title: "Treino A", status: "active")
      create(:workout_check_in, :completed, workout: workout, student: student)
      workout.archive!

      get "/api/v1/students/#{student.id}/check_ins", headers: auth_headers(student_user)

      expect(json_body["data"].first["workout_title"]).to eq("Treino A")
    end

    it "allows an admin to view any student's history" do
      create(:workout_check_in, :completed, workout: create(:workout, student: student), student: student)
      get "/api/v1/students/#{student.id}/check_ins", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
    end

    it "forbids a personal outside the student's portfolio" do
      other_personal = create(:user, :personal)
      get "/api/v1/students/#{student.id}/check_ins", headers: auth_headers(other_personal)

      expect(response).to have_http_status(:forbidden)
    end
  end
end
