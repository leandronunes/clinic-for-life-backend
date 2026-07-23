require "rails_helper"

RSpec.describe "Api::V1::StudentMigrationRequests", type: :request do
  let(:source_org) { create(:organization) }
  let(:target_org) { create(:organization) }
  let(:source_trainer) { create(:trainer, organization: source_org) }
  let(:student) { create(:student, trainer: source_trainer, organization: source_org) }
  let(:target_admin) { create(:user, :admin, organization: target_org) }

  describe "POST /api/v1/students/migration_requests" do
    it "creates a pending request when the admin invites a student from another organization" do
      expect do
        post "/api/v1/students/migration_requests", params: { email: student.email },
                                                      headers: auth_headers(target_admin)
      end.to change(StudentMigrationRequest, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json_body["data"]["status"]).to eq("pending")
      expect(json_body["data"]["requested_by_name"]).to eq(target_admin.name)
    end

    it "sends an e-mail invitation" do
      expect do
        post "/api/v1/students/migration_requests", params: { email: student.email },
                                                      headers: auth_headers(target_admin)
      end.to have_enqueued_mail(StudentMigrationRequestMailer, :invitation)
    end

    it "returns 404 when no student matches the e-mail" do
      post "/api/v1/students/migration_requests", params: { email: "nobody@email.com" },
                                                    headers: auth_headers(target_admin)
      expect(response).to have_http_status(:not_found)
      expect(json_body["code"]).to eq("student_not_found")
    end

    it "rejects inviting a student who already belongs to the requester's organization" do
      own_student = create(:student, trainer: create(:trainer, organization: target_org), organization: target_org)
      post "/api/v1/students/migration_requests", params: { email: own_student.email },
                                                    headers: auth_headers(target_admin)
      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body["code"]).to eq("already_in_organization")
    end

    it "rejects a second pending request for a student who already has one" do
      create(:student_migration_request, student: student, source_organization: source_org)
      post "/api/v1/students/migration_requests", params: { email: student.email },
                                                    headers: auth_headers(target_admin)
      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body["code"]).to eq("migration_already_pending")
    end

    it "forbids a personal from creating a migration request" do
      personal = create(:user, :personal, organization: target_org)
      post "/api/v1/students/migration_requests", params: { email: student.email },
                                                    headers: auth_headers(personal)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/v1/students/migration_requests/:id/accept" do
    let!(:request_record) do
      create(:student_migration_request, student: student, requested_by: target_admin,
                                          source_organization: source_org, target_organization: target_org)
    end
    let(:student_user) { create(:user, :student_account, student: student, organization: source_org) }

    it "moves the student into the target organization under the requester's trainer" do
      post "/api/v1/students/migration_requests/#{request_record.id}/accept", headers: auth_headers(student_user)

      expect(response).to have_http_status(:ok)
      student.reload
      expect(student.organization_id).to eq(target_org.id)
      expect(student.trainer_id).to eq(target_admin.trainer_id)
      expect(request_record.reload.status).to eq("accepted")
      expect(request_record.responded_at).to be_present
    end

    it "keeps the linked User's organization in sync" do
      student_user
      post "/api/v1/students/migration_requests/#{request_record.id}/accept", headers: auth_headers(student_user)
      expect(student_user.reload.organization_id).to eq(target_org.id)
    end

    it "forbids a different student from accepting" do
      other_student_user = create(:user, :student_account)
      post "/api/v1/students/migration_requests/#{request_record.id}/accept",
           headers: auth_headers(other_student_user)
      expect(response).to have_http_status(:forbidden)
    end

    it "forbids staff from accepting on the student's behalf" do
      post "/api/v1/students/migration_requests/#{request_record.id}/accept", headers: auth_headers(target_admin)
      expect(response).to have_http_status(:forbidden)
    end

    it "rejects re-accepting an already-resolved request" do
      request_record.update!(status: "rejected", responded_at: Time.current)
      post "/api/v1/students/migration_requests/#{request_record.id}/accept", headers: auth_headers(student_user)
      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body["code"]).to eq("migration_request_not_pending")
    end
  end

  describe "POST /api/v1/students/migration_requests/:id/reject" do
    let!(:request_record) do
      create(:student_migration_request, student: student, requested_by: target_admin,
                                          source_organization: source_org, target_organization: target_org)
    end
    let(:student_user) { create(:user, :student_account, student: student, organization: source_org) }

    it "marks the request rejected without moving the student" do
      post "/api/v1/students/migration_requests/#{request_record.id}/reject", headers: auth_headers(student_user)

      expect(response).to have_http_status(:ok)
      expect(request_record.reload.status).to eq("rejected")
      expect(student.reload.organization_id).to eq(source_org.id)
    end

    it "forbids a different student from rejecting" do
      other_student_user = create(:user, :student_account)
      post "/api/v1/students/migration_requests/#{request_record.id}/reject",
           headers: auth_headers(other_student_user)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
