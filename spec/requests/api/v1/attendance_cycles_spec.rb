require "rails_helper"

RSpec.describe "Api::V1::AttendanceCycles", type: :request do
  let(:trainer) { create(:trainer) }
  let(:admin) { create(:user, :admin) }
  let(:personal) { create(:user, :personal, trainer: trainer) }

  describe "GET /api/v1/students/:student_id/attendance_cycles" do
    it "lists an admin's closed cycles ordered most recent first, with computed completion" do
      student = create(:student, trainer: trainer)
      workout = create(:workout, student: student)
      older = create(:attendance_cycle, student: student, started_at: 4.months.ago, ended_at: 3.months.ago,
                                         contracted_workouts_per_cycle: 4)
      newer = create(:attendance_cycle, student: student, started_at: 2.months.ago, ended_at: 1.month.ago,
                                         contracted_workouts_per_cycle: 4)
      create(:workout_check_in, :completed, :mutually_confirmed, workout: workout, student: student,
                                                                      completed_at: 6.weeks.ago)
      create(:workout_check_in, :completed, :mutually_confirmed, workout: workout, student: student,
                                                                      completed_at: 5.weeks.ago)

      get "/api/v1/students/#{student.id}/attendance_cycles", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      ids = json_body["data"].map { |c| c["id"] }
      expect(ids).to eq([ newer.id.to_s, older.id.to_s ])
      newer_json = json_body["data"].find { |c| c["id"] == newer.id.to_s }
      expect(newer_json["completed_workouts"]).to eq(2)
      expect(newer_json["contracted_workouts_per_cycle"]).to eq(4)
      expect(newer_json["status"]).to eq("completed")
    end

    it "flags a cycle where completed workouts exceeded the contracted quota" do
      student = create(:student, trainer: trainer)
      workout = create(:workout, student: student)
      cycle = create(:attendance_cycle, student: student, started_at: 2.months.ago, ended_at: 1.month.ago,
                                         contracted_workouts_per_cycle: 1)
      create(:workout_check_in, :completed, :mutually_confirmed, workout: workout, student: student,
                                                                      completed_at: 6.weeks.ago)
      create(:workout_check_in, :completed, :mutually_confirmed, workout: workout, student: student,
                                                                      completed_at: 5.weeks.ago)

      get "/api/v1/students/#{student.id}/attendance_cycles", headers: auth_headers(admin)

      cycle_json = json_body["data"].find { |c| c["id"] == cycle.id.to_s }
      expect(cycle_json["status"]).to eq("exceeded")
    end

    it "returns an empty array when the student has no closed cycles yet" do
      student = create(:student, trainer: trainer)
      get "/api/v1/students/#{student.id}/attendance_cycles", headers: auth_headers(admin)
      expect(json_body["data"]).to eq([])
    end

    it "lets a personal read their own student's history" do
      student = create(:student, trainer: trainer)
      create(:attendance_cycle, student: student)
      get "/api/v1/students/#{student.id}/attendance_cycles", headers: auth_headers(personal)
      expect(response).to have_http_status(:ok)
    end

    it "forbids a personal from reading another trainer's student history" do
      other = create(:student)
      get "/api/v1/students/#{other.id}/attendance_cycles", headers: auth_headers(personal)
      expect(response).to have_http_status(:forbidden)
    end

    it "lets a student read their own history" do
      student = create(:student, trainer: trainer)
      create(:attendance_cycle, student: student)
      student_user = create(:user, :student_account, student: student)
      get "/api/v1/students/#{student.id}/attendance_cycles", headers: auth_headers(student_user)
      expect(response).to have_http_status(:ok)
      expect(json_body["data"].size).to eq(1)
    end

    it "forbids a student from reading another student's history" do
      student = create(:student, trainer: trainer)
      create(:attendance_cycle, student: student)
      other_student_user = create(:user, :student_account)
      get "/api/v1/students/#{student.id}/attendance_cycles", headers: auth_headers(other_student_user)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
