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
