require "rails_helper"

RSpec.describe "Api::V1::Students", type: :request do
  let(:trainer) { create(:trainer) }
  let(:admin) { create(:user, :admin, organization: trainer.organization) }
  let(:personal) { create(:user, :personal, trainer: trainer) }

  describe "GET /api/v1/students" do
    it "lists all students for an admin" do
      create_list(:student, 3, trainer: create(:trainer, organization: admin.organization))
      get "/api/v1/students", headers: auth_headers(admin)
      expect(response).to have_http_status(:ok)
      expect(json_body["meta"]["total"]).to eq(3)
    end

    it "does not include students from another organization" do
      create(:student, trainer: create(:trainer, organization: admin.organization))
      create(:student) # different organization entirely
      get "/api/v1/students", headers: auth_headers(admin)
      expect(json_body["meta"]["total"]).to eq(1)
    end

    it "scopes the list to the personal's portfolio" do
      create(:student, trainer: trainer)
      create(:student) # another trainer
      get "/api/v1/students", headers: auth_headers(personal)
      expect(json_body["meta"]["total"]).to eq(1)
    end

    it "filters by status" do
      create(:student, status: "active")
      create(:student, status: "inactive")
      get "/api/v1/students", params: { status: "inactive" }, headers: auth_headers(admin)
      expect(json_body["data"].map { |s| s["status"] }).to all(eq("inactive"))
    end

    it "filters by query" do
      org = admin.organization
      create(:student, name: "Julia Ferreira", trainer: create(:trainer, organization: org))
      create(:student, name: "Pedro", trainer: create(:trainer, organization: org))
      get "/api/v1/students", params: { query: "julia" }, headers: auth_headers(admin)
      expect(json_body["data"].map { |s| s["name"] }).to include("Julia Ferreira")
    end
  end

  describe "GET /api/v1/students/:id" do
    it "lets a personal read their own student" do
      student = create(:student, trainer: trainer)
      get "/api/v1/students/#{student.id}", headers: auth_headers(personal)
      expect(response).to have_http_status(:ok)
    end

    it "forbids a personal from reading another trainer's student" do
      other = create(:student)
      get "/api/v1/students/#{other.id}", headers: auth_headers(personal)
      expect(response).to have_http_status(:forbidden)
    end

    it "lets a student read only their own record" do
      student = create(:student)
      user = create(:user, :student_account, student: student)
      get "/api/v1/students/#{student.id}", headers: auth_headers(user)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /api/v1/students" do
    let(:valid_params) do
      { name: "New Student", email: "newstud@email.com", sex: "female", status: "active" }
    end

    it "creates a student and assigns the personal's trainer" do
      expect do
        post "/api/v1/students", params: valid_params, headers: auth_headers(personal)
      end.to change(Student, :count).by(1)
      expect(Student.last.trainer_id).to eq(trainer.id)
    end

    it "rejects invalid data" do
      post "/api/v1/students", params: valid_params.merge(email: ""), headers: auth_headers(admin)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "forbids a student from creating students" do
      student_user = create(:user, :student_account)
      post "/api/v1/students", params: valid_params, headers: auth_headers(student_user)
      expect(response).to have_http_status(:forbidden)
    end

    it "defaults partner_card_enabled to true" do
      post "/api/v1/students", params: valid_params, headers: auth_headers(admin)
      expect(json_body["data"]["partner_card_enabled"]).to be(true)
    end

    it "lets an admin disable the partner card on create" do
      post "/api/v1/students", params: valid_params.merge(partner_card_enabled: false),
                                headers: auth_headers(admin)
      expect(json_body["data"]["partner_card_enabled"]).to be(false)
    end

    it "ignores partner_card_enabled sent by a personal" do
      post "/api/v1/students", params: valid_params.merge(partner_card_enabled: false),
                                headers: auth_headers(personal)
      expect(Student.last.partner_card_enabled).to be(true)
    end

    it "lets a personal set the contracted workouts per cycle" do
      post "/api/v1/students", params: valid_params.merge(contracted_workouts_per_cycle: 8),
                                headers: auth_headers(personal)
      expect(Student.last.contracted_workouts_per_cycle).to eq(8)
    end

    it "persists the cpf" do
      post "/api/v1/students", params: valid_params.merge(cpf: "11122233344"), headers: auth_headers(admin)
      expect(response).to have_http_status(:created)
      expect(json_body["data"]["cpf"]).to eq("11122233344")
    end

    it "rejects a duplicate cpf" do
      create(:student, cpf: "11122233344", trainer: trainer)
      post "/api/v1/students", params: valid_params.merge(cpf: "11122233344"), headers: auth_headers(admin)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns a friendly same-organization duplicate email error" do
      create(:student, email: "taken@email.com", trainer: trainer)
      expect do
        post "/api/v1/students", params: valid_params.merge(email: "TAKEN@email.com"), headers: auth_headers(admin)
      end.not_to change(Student, :count)
      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body["code"]).to eq("email_taken_same_organization")
    end

    it "returns a cross-organization duplicate email error without leaking the other org" do
      other = create(:student, email: "taken@email.com")
      expect(other.organization_id).not_to eq(admin.organization_id)

      expect do
        post "/api/v1/students", params: valid_params.merge(email: "taken@email.com"), headers: auth_headers(admin)
      end.not_to change(Student, :count)
      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body["code"]).to eq("email_taken_other_organization")
      expect(json_body["error"]).not_to include(other.organization.name)
    end
  end

  describe "PATCH /api/v1/students/:id" do
    it "updates a student" do
      student = create(:student, trainer: trainer)
      patch "/api/v1/students/#{student.id}", params: { name: "Renamed" }, headers: auth_headers(personal)
      expect(student.reload.name).to eq("Renamed")
    end

    it "updates the cpf" do
      student = create(:student, trainer: trainer)
      patch "/api/v1/students/#{student.id}", params: { cpf: "11122233344" }, headers: auth_headers(personal)
      expect(student.reload.cpf).to eq("11122233344")
    end

    it "lets a student update their own profile" do
      student = create(:student, trainer: trainer)
      student_user = create(:user, :student_account, student: student)

      patch "/api/v1/students/#{student.id}", params: { name: "Renamed by self" },
                                               headers: auth_headers(student_user)

      expect(response).to have_http_status(:ok)
      expect(student.reload.name).to eq("Renamed by self")
    end

    it "lets a student switch their own trainer" do
      # Mesma organização do trainer original — trocar de personal dentro
      # da mesma clínica é o caso suportado; trocar de organização não é
      # (Student#organization_matches_trainer barra isso de propósito).
      new_trainer = create(:trainer, organization: trainer.organization)
      student = create(:student, trainer: trainer)
      student_user = create(:user, :student_account, student: student)

      patch "/api/v1/students/#{student.id}", params: { trainer_id: new_trainer.id },
                                               headers: auth_headers(student_user)

      expect(response).to have_http_status(:ok)
      expect(student.reload.trainer_id).to eq(new_trainer.id)
    end

    it "forbids a student from updating another student's profile" do
      student = create(:student, trainer: trainer)
      other_student_user = create(:user, :student_account)

      patch "/api/v1/students/#{student.id}", params: { name: "Hijacked" },
                                               headers: auth_headers(other_student_user)

      expect(response).to have_http_status(:forbidden)
      expect(student.reload.name).not_to eq("Hijacked")
    end

    it "lets an admin disable a student's partner card" do
      student = create(:student, trainer: trainer)
      patch "/api/v1/students/#{student.id}", params: { partner_card_enabled: false },
                                               headers: auth_headers(admin)
      expect(student.reload.partner_card_enabled).to be(false)
    end

    it "lets an admin re-enable a student's partner card" do
      student = create(:student, trainer: trainer, partner_card_enabled: false)
      patch "/api/v1/students/#{student.id}", params: { partner_card_enabled: true },
                                               headers: auth_headers(admin)
      expect(student.reload.partner_card_enabled).to be(true)
    end

    it "ignores partner_card_enabled sent by a personal" do
      student = create(:student, trainer: trainer)
      patch "/api/v1/students/#{student.id}", params: { partner_card_enabled: false },
                                               headers: auth_headers(personal)
      expect(response).to have_http_status(:ok)
      expect(student.reload.partner_card_enabled).to be(true)
    end

    it "ignores partner_card_enabled sent by the student themselves" do
      student = create(:student, trainer: trainer)
      student_user = create(:user, :student_account, student: student)
      patch "/api/v1/students/#{student.id}", params: { partner_card_enabled: false },
                                               headers: auth_headers(student_user)
      expect(response).to have_http_status(:ok)
      expect(student.reload.partner_card_enabled).to be(true)
    end

    it "lets a personal set the contracted workouts per cycle for their own student" do
      student = create(:student, trainer: trainer)
      patch "/api/v1/students/#{student.id}", params: { contracted_workouts_per_cycle: 12 },
                                               headers: auth_headers(personal)
      expect(student.reload.contracted_workouts_per_cycle).to eq(12)
    end

    it "ignores contracted_workouts_per_cycle sent by the student themselves" do
      student = create(:student, trainer: trainer, contracted_workouts_per_cycle: 8)
      student_user = create(:user, :student_account, student: student)
      patch "/api/v1/students/#{student.id}", params: { contracted_workouts_per_cycle: 999 },
                                               headers: auth_headers(student_user)
      expect(response).to have_http_status(:ok)
      expect(student.reload.contracted_workouts_per_cycle).to eq(8)
    end

    it "lets an admin reset a student's cycle_started_at directly (e.g. when the quota changes)" do
      student = create(:student, trainer: trainer, cycle_started_at: 2.months.ago)
      new_start = Time.current.iso8601
      patch "/api/v1/students/#{student.id}", params: { cycle_started_at: new_start },
                                               headers: auth_headers(admin)
      expect(student.reload.cycle_started_at.iso8601).to eq(new_start)
    end

    it "ignores cycle_started_at sent by the student themselves" do
      original_start = 1.month.ago
      student = create(:student, trainer: trainer, cycle_started_at: original_start)
      student_user = create(:user, :student_account, student: student)
      patch "/api/v1/students/#{student.id}", params: { cycle_started_at: Time.current.iso8601 },
                                               headers: auth_headers(student_user)
      expect(response).to have_http_status(:ok)
      expect(student.reload.cycle_started_at).to be_within(1.second).of(original_start)
    end

    it "rejects a zero contracted_workouts_per_cycle" do
      student = create(:student, trainer: trainer)
      patch "/api/v1/students/#{student.id}", params: { contracted_workouts_per_cycle: 0 },
                                               headers: auth_headers(admin)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "POST /api/v1/students/:id/renew_cycle" do
    it "archives the current cycle and starts a new one" do
      student = create(:student, trainer: trainer, contracted_workouts_per_cycle: 8,
                                  cycle_started_at: 2.months.ago)

      expect do
        post "/api/v1/students/#{student.id}/renew_cycle", headers: auth_headers(admin)
      end.to change(AttendanceCycle, :count).by(1)

      expect(response).to have_http_status(:ok)
      archived = AttendanceCycle.last
      expect(archived.student).to eq(student)
      expect(archived.contracted_workouts_per_cycle).to eq(8)
      expect(archived.started_at).to be_within(1.second).of(2.months.ago)
      expect(student.reload.cycle_started_at).to be_within(1.second).of(Time.current)
    end

    it "falls back to the student's created_at as the archived cycle's start when never set" do
      student = create(:student, trainer: trainer, contracted_workouts_per_cycle: 8, cycle_started_at: nil)

      post "/api/v1/students/#{student.id}/renew_cycle", headers: auth_headers(admin)

      expect(AttendanceCycle.last.started_at).to be_within(1.second).of(student.created_at)
    end

    it "lets a personal renew their own student's cycle" do
      student = create(:student, trainer: trainer, contracted_workouts_per_cycle: 8)
      post "/api/v1/students/#{student.id}/renew_cycle", headers: auth_headers(personal)
      expect(response).to have_http_status(:ok)
    end

    it "forbids a personal from renewing another trainer's student" do
      other = create(:student, contracted_workouts_per_cycle: 8)
      post "/api/v1/students/#{other.id}/renew_cycle", headers: auth_headers(personal)
      expect(response).to have_http_status(:forbidden)
    end

    it "forbids the student themselves from renewing their own cycle" do
      student = create(:student, trainer: trainer, contracted_workouts_per_cycle: 8)
      student_user = create(:user, :student_account, student: student)
      post "/api/v1/students/#{student.id}/renew_cycle", headers: auth_headers(student_user)
      expect(response).to have_http_status(:forbidden)
    end

    it "rejects renewal when the student has no contracted quota" do
      student = create(:student, trainer: trainer, contracted_workouts_per_cycle: nil)
      post "/api/v1/students/#{student.id}/renew_cycle", headers: auth_headers(admin)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "records an audit log on renewal" do
      student = create(:student, trainer: trainer, contracted_workouts_per_cycle: 8)
      expect do
        post "/api/v1/students/#{student.id}/renew_cycle", headers: auth_headers(admin)
      end.to change(AuditLog, :count).by(1)
      expect(AuditLog.last.action).to eq("student.renew_cycle")
    end
  end

  describe "DELETE /api/v1/students/:id" do
    it "destroys the student as admin and returns 204" do
      student = create(:student, trainer: create(:trainer, organization: admin.organization))
      expect do
        delete "/api/v1/students/#{student.id}", headers: auth_headers(admin)
      end.to change(Student, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end

    it "records an audit log on deletion" do
      student = create(:student, trainer: create(:trainer, organization: admin.organization))
      expect do
        delete "/api/v1/students/#{student.id}", headers: auth_headers(admin)
      end.to change(AuditLog, :count).by(1)
      expect(AuditLog.last.action).to eq("student.destroy")
    end

    it "forbids a personal from deleting a student" do
      student = create(:student, trainer: trainer)
      delete "/api/v1/students/#{student.id}", headers: auth_headers(personal)
      expect(response).to have_http_status(:forbidden)
      expect(Student.exists?(student.id)).to be true
    end

    it "returns 404 for an unknown student" do
      delete "/api/v1/students/999999", headers: auth_headers(admin)
      expect(response).to have_http_status(:not_found)
    end

    it "forbids an admin from deleting a student in another organization" do
      other_org_student = create(:student)
      delete "/api/v1/students/#{other_org_student.id}", headers: auth_headers(admin)
      expect(response).to have_http_status(:forbidden)
      expect(Student.exists?(other_org_student.id)).to be true
    end

    it "cascades deletion to associated exams" do
      student = create(:student, trainer: create(:trainer, organization: admin.organization))
      create(:exam, student: student)
      expect do
        delete "/api/v1/students/#{student.id}", headers: auth_headers(admin)
      end.to change(Exam, :count).by(-1)
    end

    it "deletes the student even when bioimpedance measurements have linked evolution photos" do
      student = create(:student, trainer: create(:trainer, organization: admin.organization))
      measurement = create(:bioimpedance_measurement, student: student)
      create(:evolution_photo, student: student, bioimpedance_measurement: measurement)

      expect do
        delete "/api/v1/students/#{student.id}", headers: auth_headers(admin)
      end.to change(Student, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end
  end
end
