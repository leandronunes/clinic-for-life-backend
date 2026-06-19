require "rails_helper"

RSpec.describe "Api::V1::Trainers", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:personal) { create(:user, :personal) }

  describe "GET /api/v1/trainers" do
    it "lists trainers for an authenticated user" do
      create_list(:trainer, 2)
      get "/api/v1/trainers", headers: auth_headers(admin)
      expect(response).to have_http_status(:ok)
      expect(json_body["meta"]["total"]).to be >= 2
    end
  end

  describe "GET /api/v1/trainers/search" do
    it "filters active trainers by query" do
      create(:trainer, name: "Rafael Monteiro", status: "active")
      create(:trainer, name: "Outro", status: "blocked")
      get "/api/v1/trainers/search", params: { query: "rafael" }, headers: auth_headers(admin)

      names = json_body["data"].map { |t| t["name"] }
      expect(names).to include("Rafael Monteiro")
      expect(names).not_to include("Outro")
    end

    it "returns active trainers when query is blank" do
      create(:trainer, status: "active")
      get "/api/v1/trainers/search", headers: auth_headers(admin)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /api/v1/trainers/:id" do
    it "returns a single trainer" do
      trainer = create(:trainer)
      get "/api/v1/trainers/#{trainer.id}", headers: auth_headers(admin)
      expect(json_body["data"]["id"]).to eq(trainer.id.to_s)
    end

    it "returns 404 for an unknown trainer" do
      get "/api/v1/trainers/999999", headers: auth_headers(admin)
      expect(response).to have_http_status(:not_found)
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
      trainer = create(:trainer)
      patch "/api/v1/trainers/#{trainer.id}", params: { name: "Renamed" }, headers: auth_headers(admin)
      expect(response).to have_http_status(:ok)
      expect(trainer.reload.name).to eq("Renamed")
    end
  end

  describe "DELETE /api/v1/trainers/:id" do
    it "destroys the trainer as admin and returns 204" do
      trainer = create(:trainer)
      expect do
        delete "/api/v1/trainers/#{trainer.id}", headers: auth_headers(admin)
      end.to change(Trainer, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end

    it "records an audit log on deletion" do
      trainer = create(:trainer)
      expect do
        delete "/api/v1/trainers/#{trainer.id}", headers: auth_headers(admin)
      end.to change(AuditLog, :count).by(1)
      expect(AuditLog.last.action).to eq("trainer.destroy")
    end

    it "nullifies associated students' trainer_id instead of cascading" do
      trainer_record = create(:trainer)
      student = create(:student, trainer: trainer_record)
      delete "/api/v1/trainers/#{trainer_record.id}", headers: auth_headers(admin)
      expect(Student.exists?(student.id)).to be true
      expect(student.reload.trainer_id).to be_nil
    end

    it "forbids a personal from deleting a trainer" do
      trainer_record = create(:trainer)
      delete "/api/v1/trainers/#{trainer_record.id}", headers: auth_headers(personal)
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 404 for an unknown trainer" do
      delete "/api/v1/trainers/999999", headers: auth_headers(admin)
      expect(response).to have_http_status(:not_found)
    end
  end
end
