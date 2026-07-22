require "rails_helper"

RSpec.describe "Api::V1::Trainers", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:personal) { create(:user, :personal) }

  describe "GET /api/v1/trainers" do
    it "lists trainers for an authenticated user" do
      create_list(:trainer, 2, organization: admin.organization)
      get "/api/v1/trainers", headers: auth_headers(admin)
      expect(response).to have_http_status(:ok)
      expect(json_body["meta"]["total"]).to be >= 2
    end

    it "does not include trainers from another organization" do
      create(:trainer, organization: admin.organization)
      create(:trainer) # different organization entirely
      get "/api/v1/trainers", headers: auth_headers(admin)
      expect(json_body["meta"]["total"]).to eq(1)
    end

    it "does not filter by status when the param is absent" do
      create(:trainer, name: "Rafael Monteiro", status: "active", organization: admin.organization)
      create(:trainer, name: "Marina Souza", status: "inactive", organization: admin.organization)
      get "/api/v1/trainers", headers: auth_headers(admin)

      names = json_body["data"].map { |t| t["name"] }
      expect(names).to include("Rafael Monteiro", "Marina Souza")
    end

    it "filters trainers by a single status" do
      create(:trainer, name: "Rafael Monteiro", status: "active", organization: admin.organization)
      create(:trainer, name: "Marina Souza", status: "inactive", organization: admin.organization)
      get "/api/v1/trainers", params: { status: "active" }, headers: auth_headers(admin)

      names = json_body["data"].map { |t| t["name"] }
      expect(names).to include("Rafael Monteiro")
      expect(names).not_to include("Marina Souza")
    end

    it "filters trainers by multiple comma-separated statuses" do
      create(:trainer, name: "Rafael Monteiro", status: "active", organization: admin.organization)
      create(:trainer, name: "Carlos Eduardo", status: "blocked", organization: admin.organization)
      create(:trainer, name: "Marina Souza", status: "inactive", organization: admin.organization)
      get "/api/v1/trainers", params: { status: "active,blocked" }, headers: auth_headers(admin)

      names = json_body["data"].map { |t| t["name"] }
      expect(names).to include("Rafael Monteiro", "Carlos Eduardo")
      expect(names).not_to include("Marina Souza")
    end
  end

  describe "GET /api/v1/trainers/search" do
    it "filters trainers by query" do
      create(:trainer, name: "Rafael Monteiro", status: "active", organization: admin.organization)
      create(:trainer, name: "Outro Rafael", status: "blocked", organization: admin.organization)
      get "/api/v1/trainers/search", params: { query: "rafael" }, headers: auth_headers(admin)

      names = json_body["data"].map { |t| t["name"] }
      expect(names).to include("Rafael Monteiro", "Outro Rafael")
    end

    it "combines query and status filters" do
      create(:trainer, name: "Rafael Monteiro", status: "active", organization: admin.organization)
      create(:trainer, name: "Rafael Blocked", status: "blocked", organization: admin.organization)
      get "/api/v1/trainers/search", params: { query: "rafael", status: "active" },
                                      headers: auth_headers(admin)

      names = json_body["data"].map { |t| t["name"] }
      expect(names).to include("Rafael Monteiro")
      expect(names).not_to include("Rafael Blocked")
    end

    it "returns trainers when query is blank" do
      create(:trainer, status: "active", organization: admin.organization)
      get "/api/v1/trainers/search", headers: auth_headers(admin)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /api/v1/trainers/:id" do
    it "returns a single trainer" do
      trainer = create(:trainer, organization: admin.organization)
      get "/api/v1/trainers/#{trainer.id}", headers: auth_headers(admin)
      expect(json_body["data"]["id"]).to eq(trainer.id.to_s)
    end

    it "returns 404 for an unknown trainer" do
      get "/api/v1/trainers/999999", headers: auth_headers(admin)
      expect(response).to have_http_status(:not_found)
    end

    it "forbids an admin from viewing a trainer in another organization" do
      trainer = create(:trainer) # different organization entirely
      get "/api/v1/trainers/#{trainer.id}", headers: auth_headers(admin)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/v1/trainers" do
    let(:valid_params) do
      { name: "New Trainer", cpf: "98765432100", cref: "099999-G/SP",
        email: "new@forlife.app", status: "active" }
    end

    it "creates a trainer as admin and records an audit log" do
      expect do
        post "/api/v1/trainers", params: valid_params, headers: auth_headers(admin)
      end.to change(Trainer, :count).by(1).and change(AuditLog, :count).by(1)
      expect(response).to have_http_status(:created)
    end

    it "rejects invalid data" do
      post "/api/v1/trainers", params: valid_params.merge(email: "bad"), headers: auth_headers(admin)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "forbids a personal from creating trainers" do
      post "/api/v1/trainers", params: valid_params, headers: auth_headers(personal)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "PATCH /api/v1/trainers/:id" do
    it "updates a trainer as admin" do
      trainer = create(:trainer, organization: admin.organization)
      patch "/api/v1/trainers/#{trainer.id}", params: { name: "Renamed" }, headers: auth_headers(admin)
      expect(response).to have_http_status(:ok)
      expect(trainer.reload.name).to eq("Renamed")
    end

    it "forbids an admin from updating a trainer in another organization" do
      trainer = create(:trainer) # different organization entirely
      patch "/api/v1/trainers/#{trainer.id}", params: { name: "Renamed" }, headers: auth_headers(admin)
      expect(response).to have_http_status(:forbidden)
      expect(trainer.reload.name).not_to eq("Renamed")
    end
  end

  describe "DELETE /api/v1/trainers/:id" do
    it "destroys the trainer as admin and returns 204" do
      trainer = create(:trainer, organization: admin.organization)
      expect do
        delete "/api/v1/trainers/#{trainer.id}", headers: auth_headers(admin)
      end.to change(Trainer, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end

    it "records an audit log on deletion" do
      trainer = create(:trainer, organization: admin.organization)
      expect do
        delete "/api/v1/trainers/#{trainer.id}", headers: auth_headers(admin)
      end.to change(AuditLog, :count).by(1)
      expect(AuditLog.last.action).to eq("trainer.destroy")
    end

    it "nullifies associated students' trainer_id instead of cascading" do
      trainer_record = create(:trainer, organization: admin.organization)
      student = create(:student, trainer: trainer_record, organization: admin.organization)
      delete "/api/v1/trainers/#{trainer_record.id}", headers: auth_headers(admin)
      expect(Student.exists?(student.id)).to be true
      expect(student.reload.trainer_id).to be_nil
    end

    it "forbids a personal from deleting a trainer" do
      trainer_record = create(:trainer)
      delete "/api/v1/trainers/#{trainer_record.id}", headers: auth_headers(personal)
      expect(response).to have_http_status(:forbidden)
    end

    it "forbids an admin from deleting a trainer in another organization" do
      trainer_record = create(:trainer) # different organization entirely
      delete "/api/v1/trainers/#{trainer_record.id}", headers: auth_headers(admin)
      expect(response).to have_http_status(:forbidden)
      expect(Trainer.exists?(trainer_record.id)).to be true
    end

    it "returns 404 for an unknown trainer" do
      delete "/api/v1/trainers/999999", headers: auth_headers(admin)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/trainers?pending=true" do
    it "returns only trainers awaiting approval within the admin's organization" do
      create(:trainer, organization: admin.organization, approved_at: nil)
      create(:trainer, organization: admin.organization) # already approved
      get "/api/v1/trainers", params: { pending: "true" }, headers: auth_headers(admin)

      expect(json_body["meta"]["total"]).to eq(1)
      expect(json_body["data"].first["approved_at"]).to be_nil
    end
  end

  describe "PATCH /api/v1/trainers/:id/approve" do
    it "stamps approved_at and records an audit log" do
      trainer = create(:trainer, organization: admin.organization, approved_at: nil)
      patch "/api/v1/trainers/#{trainer.id}/approve", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(json_body["data"]["approved_at"]).to be_present
      expect(trainer.reload.approved_at).to be_present
      expect(AuditLog.last.action).to eq("trainer.approve")
    end

    it "is idempotent for an already-approved trainer" do
      trainer = create(:trainer, organization: admin.organization)
      approved_at = trainer.approved_at
      patch "/api/v1/trainers/#{trainer.id}/approve", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(trainer.reload.approved_at).to be_within(1.second).of(approved_at)
    end

    it "forbids an admin from approving a trainer in another organization" do
      trainer = create(:trainer, approved_at: nil) # different organization entirely
      patch "/api/v1/trainers/#{trainer.id}/approve", headers: auth_headers(admin)

      expect(response).to have_http_status(:forbidden)
      expect(trainer.reload.approved_at).to be_nil
    end

    it "forbids a personal from approving a trainer" do
      trainer = create(:trainer, organization: personal.organization, approved_at: nil)
      patch "/api/v1/trainers/#{trainer.id}/approve", headers: auth_headers(personal)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "DELETE /api/v1/trainers/:id/reject" do
    it "destroys both the trainer and its user in one transaction" do
      trainer = create(:trainer, organization: admin.organization, approved_at: nil)
      user = create(:user, :personal, trainer: trainer, organization: admin.organization)

      delete "/api/v1/trainers/#{trainer.id}/reject", headers: auth_headers(admin)

      expect(response).to have_http_status(:no_content)
      expect(Trainer.exists?(trainer.id)).to be false
      expect(User.exists?(user.id)).to be false
    end

    it "records an audit log on rejection" do
      trainer = create(:trainer, organization: admin.organization, approved_at: nil)
      delete "/api/v1/trainers/#{trainer.id}/reject", headers: auth_headers(admin)
      expect(AuditLog.last.action).to eq("trainer.reject")
    end

    it "forbids an admin from rejecting a trainer in another organization" do
      trainer = create(:trainer, approved_at: nil) # different organization entirely
      delete "/api/v1/trainers/#{trainer.id}/reject", headers: auth_headers(admin)

      expect(response).to have_http_status(:forbidden)
      expect(Trainer.exists?(trainer.id)).to be true
    end
  end
end
