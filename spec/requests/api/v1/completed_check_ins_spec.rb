require "rails_helper"

RSpec.describe "Api::V1::CompletedCheckIns", type: :request do
  let(:trainer) { create(:trainer) }
  let(:personal) { create(:user, :personal, trainer: trainer) }
  let(:admin) { create(:user, :admin, organization: trainer.organization) }
  let(:student) { create(:student, trainer: trainer) }
  let(:student_user) { create(:user, :student_account, student: student) }
  let(:workout) { create(:workout, student: student) }

  describe "GET /api/v1/completed_check_ins" do
    it "lists completed check-ins for the personal's own portfolio" do
      create(:workout_check_in, :completed, workout: workout, student: student)
      other_student = create(:student, trainer: create(:trainer))
      create(:workout_check_in, :completed, workout: create(:workout, student: other_student),
                                             student: other_student)

      get "/api/v1/completed_check_ins", headers: auth_headers(personal)

      expect(response).to have_http_status(:ok)
      expect(json_body["data"].size).to eq(1)
      expect(json_body["data"].first["student_id"]).to eq(student.id.to_s)
    end

    it "lists completed check-ins across all students for an admin" do
      create(:workout_check_in, :completed, workout: workout, student: student)
      other_student = create(:student, trainer: create(:trainer, organization: admin.organization))
      create(:workout_check_in, :completed, workout: create(:workout, student: other_student),
                                             student: other_student)

      get "/api/v1/completed_check_ins", headers: auth_headers(admin)

      expect(json_body["data"].size).to eq(2)
    end

    it "does not include check-ins from another organization for an admin" do
      create(:workout_check_in, :completed, workout: workout, student: student)
      outside_student = create(:student) # own independent organization
      create(:workout_check_in, :completed, workout: create(:workout, student: outside_student),
                                             student: outside_student)

      get "/api/v1/completed_check_ins", headers: auth_headers(admin)

      expect(json_body["data"].size).to eq(1)
      expect(json_body["data"].first["student_id"]).to eq(student.id.to_s)
    end

    it "excludes in-progress check-ins" do
      create(:workout_check_in, workout: workout, student: student)

      get "/api/v1/completed_check_ins", headers: auth_headers(personal)

      expect(json_body["data"]).to be_empty
    end

    it "orders results most recently completed first" do
      older = create(:workout_check_in, :completed, workout: workout, student: student,
                                                      completed_at: 2.days.ago)
      newer = create(:workout_check_in, :completed, workout: create(:workout, student: student), student: student,
                                                      completed_at: 1.hour.ago)

      get "/api/v1/completed_check_ins", headers: auth_headers(personal)

      ids = json_body["data"].map { |c| c["id"] }
      expect(ids).to eq([ newer.id.to_s, older.id.to_s ])
    end

    it "forbids a student from accessing the endpoint" do
      get "/api/v1/completed_check_ins", headers: auth_headers(student_user)

      expect(response).to have_http_status(:forbidden)
    end
  end
end
