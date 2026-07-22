require "rails_helper"

RSpec.describe "Api::V1::ScheduleSessions", type: :request do
  let(:trainer) { create(:trainer) }
  let(:personal) { create(:user, :personal, trainer: trainer) }
  let(:admin) { create(:user, :admin, organization: trainer.organization) }
  let(:student) { create(:student, trainer: trainer) }
  let(:student_user) { create(:user, :student_account, student: student) }

  describe "GET /api/v1/schedule_sessions" do
    it "returns 422 when from/to are missing" do
      get "/api/v1/schedule_sessions", headers: auth_headers(personal)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "lists sessions within the requested range" do
      create(:schedule_session, student: student, trainer: trainer, starts_at: "2026-07-06T07:00:00-03:00")
      create(:schedule_session, student: student, trainer: trainer, starts_at: "2026-08-01T07:00:00-03:00")

      get "/api/v1/schedule_sessions", params: { from: "2026-07-01", to: "2026-07-31" },
                                        headers: auth_headers(personal)

      expect(response).to have_http_status(:ok)
      expect(json_body["data"].size).to eq(1)
    end

    it "scopes results to the personal's own portfolio" do
      create(:schedule_session, student: student, trainer: trainer, starts_at: "2026-07-06T07:00:00-03:00")
      other_trainer = create(:trainer)
      other_student = create(:student, trainer: other_trainer)
      create(:schedule_session, student: other_student, trainer: other_trainer,
                                 starts_at: "2026-07-06T08:00:00-03:00")

      get "/api/v1/schedule_sessions", params: { from: "2026-07-01", to: "2026-07-31" },
                                        headers: auth_headers(personal)

      expect(json_body["data"].size).to eq(1)
      expect(json_body["data"].first["trainer_id"]).to eq(trainer.id.to_s)
    end

    it "does not leak another portfolio's sessions when a personal passes a foreign trainer_id" do
      other_trainer = create(:trainer)
      other_student = create(:student, trainer: other_trainer)
      create(:schedule_session, student: other_student, trainer: other_trainer,
                                 starts_at: "2026-07-06T08:00:00-03:00")

      get "/api/v1/schedule_sessions", params: { from: "2026-07-01", to: "2026-07-31", trainer_id: other_trainer.id },
                                        headers: auth_headers(personal)

      expect(json_body["data"]).to be_empty
    end

    it "scopes results to the student's own agenda, ignoring a foreign student_id" do
      create(:schedule_session, student: student, trainer: trainer, starts_at: "2026-07-06T07:00:00-03:00")
      other_student = create(:student, trainer: create(:trainer))
      create(:schedule_session, student: other_student, trainer: other_student.trainer,
                                 starts_at: "2026-07-06T08:00:00-03:00")

      get "/api/v1/schedule_sessions",
          params: { from: "2026-07-01", to: "2026-07-31", student_id: other_student.id },
          headers: auth_headers(student_user)

      expect(json_body["data"].size).to eq(1)
      expect(json_body["data"].first["student_id"]).to eq(student.id.to_s)
    end

    it "lets an admin see everything, and filter by trainer_id" do
      create(:schedule_session, student: student, trainer: trainer, starts_at: "2026-07-06T07:00:00-03:00")
      other_trainer = create(:trainer, organization: admin.organization)
      other_student = create(:student, trainer: other_trainer)
      create(:schedule_session, student: other_student, trainer: other_trainer,
                                 starts_at: "2026-07-06T08:00:00-03:00")

      get "/api/v1/schedule_sessions", params: { from: "2026-07-01", to: "2026-07-31" }, headers: auth_headers(admin)
      expect(json_body["data"].size).to eq(2)

      get "/api/v1/schedule_sessions", params: { from: "2026-07-01", to: "2026-07-31", trainer_id: trainer.id },
                                        headers: auth_headers(admin)
      expect(json_body["data"].size).to eq(1)
    end

    it "does not include sessions from another organization for an admin" do
      create(:schedule_session, student: student, trainer: trainer, starts_at: "2026-07-06T07:00:00-03:00")
      outside_trainer = create(:trainer) # own independent organization
      outside_student = create(:student, trainer: outside_trainer)
      create(:schedule_session, student: outside_student, trainer: outside_trainer,
                                 starts_at: "2026-07-06T08:00:00-03:00")

      get "/api/v1/schedule_sessions", params: { from: "2026-07-01", to: "2026-07-31" }, headers: auth_headers(admin)

      expect(json_body["data"].size).to eq(1)
      expect(json_body["data"].first["student_id"]).to eq(student.id.to_s)
    end

    it "orders results by starts_at ascending" do
      later = create(:schedule_session, student: student, trainer: trainer, starts_at: "2026-07-06T18:00:00-03:00")
      earlier = create(:schedule_session, student: student, trainer: trainer, starts_at: "2026-07-06T07:00:00-03:00")

      get "/api/v1/schedule_sessions", params: { from: "2026-07-01", to: "2026-07-31" },
                                        headers: auth_headers(personal)

      ids = json_body["data"].map { |s| s["id"] }
      expect(ids).to eq([ earlier.id.to_s, later.id.to_s ])
    end
  end

  describe "PATCH /api/v1/schedule_sessions/:id" do
    it "updates the session for the owning personal" do
      session = create(:schedule_session, student: student, trainer: trainer)

      patch "/api/v1/schedule_sessions/#{session.id}", params: { status: "done" }, headers: auth_headers(personal)

      expect(response).to have_http_status(:ok)
      expect(json_body["data"]["status"]).to eq("done")
      expect(session.reload.status).to eq("done")
    end

    it "forbids the student from updating their own session" do
      session = create(:schedule_session, student: student, trainer: trainer)

      patch "/api/v1/schedule_sessions/#{session.id}", params: { status: "done" }, headers: auth_headers(student_user)

      expect(response).to have_http_status(:forbidden)
    end

    it "forbids a personal outside the student's portfolio" do
      session = create(:schedule_session, student: student, trainer: trainer)
      other_personal = create(:user, :personal)

      patch "/api/v1/schedule_sessions/#{session.id}", params: { status: "done" },
                                                         headers: auth_headers(other_personal)

      expect(response).to have_http_status(:forbidden)
    end

    it "records an audit log on update" do
      session = create(:schedule_session, student: student, trainer: trainer)

      expect do
        patch "/api/v1/schedule_sessions/#{session.id}", params: { status: "done" }, headers: auth_headers(personal)
      end.to change(AuditLog, :count).by(1)
    end
  end

  describe "DELETE /api/v1/schedule_sessions/:id" do
    it "hard-deletes the session for the owning personal" do
      session = create(:schedule_session, student: student, trainer: trainer)

      expect do
        delete "/api/v1/schedule_sessions/#{session.id}", headers: auth_headers(personal)
      end.to change(ScheduleSession, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "forbids the student from deleting their own session" do
      session = create(:schedule_session, student: student, trainer: trainer)

      delete "/api/v1/schedule_sessions/#{session.id}", headers: auth_headers(student_user)

      expect(response).to have_http_status(:forbidden)
    end

    it "forbids a personal outside the student's portfolio" do
      session = create(:schedule_session, student: student, trainer: trainer)
      other_personal = create(:user, :personal)

      delete "/api/v1/schedule_sessions/#{session.id}", headers: auth_headers(other_personal)

      expect(response).to have_http_status(:forbidden)
    end

    it "returns 404 for a session that does not exist" do
      delete "/api/v1/schedule_sessions/999999", headers: auth_headers(personal)

      expect(response).to have_http_status(:not_found)
    end
  end
end
