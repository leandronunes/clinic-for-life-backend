require "rails_helper"

RSpec.describe "Api::V1::Auth", type: :request do
  describe "POST /api/v1/auth/login" do
    let!(:user) { create(:user, :admin, email: "admin@forlife.app", password: "Str0ng@Pass") }

    it "returns a token and the user on valid credentials" do
      post "/api/v1/auth/login", params: { email: "admin@forlife.app", password: "Str0ng@Pass" }

      expect(response).to have_http_status(:ok)
      expect(json_body["data"]["token"]).to be_present
      expect(json_body["data"]["user"]["email"]).to eq("admin@forlife.app")
      expect(json_body["data"]["expires_at"]).to be_present
    end

    it "is case-insensitive on the email" do
      post "/api/v1/auth/login", params: { email: "ADMIN@forlife.app", password: "Str0ng@Pass" }
      expect(response).to have_http_status(:ok)
    end

    it "updates last_login_at and records an audit log" do
      expect do
        post "/api/v1/auth/login", params: { email: "admin@forlife.app", password: "Str0ng@Pass" }
      end.to change(AuditLog, :count).by(1)
      expect(user.reload.last_login_at).to be_present
    end

    it "rejects invalid credentials" do
      post "/api/v1/auth/login", params: { email: "admin@forlife.app", password: "wrong" }
      expect(response).to have_http_status(:unauthorized)
      expect(json_body["error"]).to eq("Invalid credentials")
    end

    it "rejects an unknown email" do
      post "/api/v1/auth/login", params: { email: "ghost@forlife.app", password: "Str0ng@Pass" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/auth/register" do
    let(:valid_params) do
      {
        name: "João Silva",
        email: "joao@email.com",
        password: "Str0ng@Pass",
        password_confirmation: "Str0ng@Pass"
      }
    end

    it "creates a new student-role user and returns a session token" do
      expect do
        post "/api/v1/auth/register", params: valid_params
      end.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json_body["data"]["token"]).to be_present
      expect(json_body["data"]["user"]["email"]).to eq("joao@email.com")
      expect(json_body["data"]["user"]["role"]).to eq("student")
      expect(json_body["data"]["user"]["student_id"]).to be_nil
    end

    it "links the user to an existing student record with the same email" do
      student = create(:student, email: "joao@email.com")

      post "/api/v1/auth/register", params: valid_params

      expect(response).to have_http_status(:created)
      user = User.find_by(email: "joao@email.com")
      expect(user.student_id).to eq(student.id)
      expect(json_body["data"]["user"]["student_id"]).to eq(student.id.to_s)
      expect(json_body["data"]["user"]["role"]).to eq("student")
    end

    it "links the user to an existing trainer record with the same email and sets role to personal" do
      trainer = create(:trainer, email: "joao@email.com")

      post "/api/v1/auth/register", params: valid_params

      expect(response).to have_http_status(:created)
      user = User.find_by(email: "joao@email.com")
      expect(user.trainer_id).to eq(trainer.id)
      expect(json_body["data"]["user"]["trainer_id"]).to eq(trainer.id.to_s)
      expect(json_body["data"]["user"]["role"]).to eq("personal")
    end

    it "rejects registration when the email already has a user account" do
      create(:user, :admin, email: "joao@email.com")

      post "/api/v1/auth/register", params: valid_params

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_body["error"]).to be_present
    end

    it "rejects a weak password" do
      post "/api/v1/auth/register", params: valid_params.merge(password: "weak",
                                                               password_confirmation: "weak")

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects when passwords do not match" do
      post "/api/v1/auth/register", params: valid_params.merge(password_confirmation: "Other@Pass1")

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "records an audit log on successful registration" do
      expect do
        post "/api/v1/auth/register", params: valid_params
      end.to change(AuditLog, :count).by(1)
    end
  end

  describe "GET /api/v1/auth/me" do
    let(:user) { create(:user, :admin) }

    it "returns the current user with a valid token" do
      get "/api/v1/auth/me", headers: auth_headers(user)
      expect(response).to have_http_status(:ok)
      expect(json_body["data"]["id"]).to eq(user.id.to_s)
    end

    it "rejects requests without a token" do
      get "/api/v1/auth/me"
      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects requests with an invalid token" do
      get "/api/v1/auth/me", headers: { "Authorization" => "Bearer invalid.token" }
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
