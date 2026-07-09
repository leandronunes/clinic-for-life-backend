require "rails_helper"

RSpec.describe "Api::V1::Students", type: :request do
  let(:trainer) { create(:trainer) }
  let(:admin) { create(:user, :admin) }
  let(:personal) { create(:user, :personal, trainer: trainer) }

  describe "GET /api/v1/students" do
    it "lists all students for an admin" do
      create_list(:student, 3)
      get "/api/v1/students", headers: auth_headers(admin)
      expect(response).to have_http_status(:ok)
      expect(json_body["meta"]["total"]).to eq(3)
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
      create(:student, name: "Julia Ferreira")
      create(:student, name: "Pedro")
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
  end

  describe "PATCH /api/v1/students/:id" do
    it "updates a student" do
      student = create(:student, trainer: trainer)
      patch "/api/v1/students/#{student.id}", params: { name: "Renamed" }, headers: auth_headers(personal)
      expect(student.reload.name).to eq("Renamed")
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
      new_trainer = create(:trainer)
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
  end

  describe "DELETE /api/v1/students/:id" do
    it "destroys the student as admin and returns 204" do
      student = create(:student)
      expect do
        delete "/api/v1/students/#{student.id}", headers: auth_headers(admin)
      end.to change(Student, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end

    it "records an audit log on deletion" do
      student = create(:student)
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

    it "cascades deletion to associated exams" do
      student = create(:student)
      create(:exam, student: student)
      expect do
        delete "/api/v1/students/#{student.id}", headers: auth_headers(admin)
      end.to change(Exam, :count).by(-1)
    end

    it "deletes the student even when bioimpedance measurements have linked evolution photos" do
      student = create(:student)
      measurement = create(:bioimpedance_measurement, student: student)
      create(:evolution_photo, student: student, bioimpedance_measurement: measurement)

      expect do
        delete "/api/v1/students/#{student.id}", headers: auth_headers(admin)
      end.to change(Student, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end
  end
end
