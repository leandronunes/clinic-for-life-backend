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

  describe "POST /api/v1/auth/google" do
    let(:access_token) { "valid-google-access-token" }
    let(:google_userinfo) { { "email" => "joao@email.com", "name" => "João Silva" } }

    before do
      allow(GoogleAuthService).to receive(:fetch_userinfo)
        .with(access_token)
        .and_return(google_userinfo)
    end

    it "creates a new student-role user on first Google login and returns a token" do
      expect do
        post "/api/v1/auth/google", params: { access_token: access_token }
      end.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json_body["data"]["token"]).to be_present
      expect(json_body["data"]["user"]["email"]).to eq("joao@email.com")
      expect(json_body["data"]["user"]["role"]).to eq("student")
    end

    it "logs in an existing user without creating a new account" do
      existing = create(:user, :admin, email: "joao@email.com")

      expect do
        post "/api/v1/auth/google", params: { access_token: access_token }
      end.not_to change(User, :count)

      expect(response).to have_http_status(:ok)
      expect(json_body["data"]["user"]["id"]).to eq(existing.id.to_s)
    end

    it "links new user to an existing student record with the same email" do
      student = create(:student, email: "joao@email.com")

      post "/api/v1/auth/google", params: { access_token: access_token }

      user = User.find_by(email: "joao@email.com")
      expect(user.student_id).to eq(student.id)
      expect(json_body["data"]["user"]["student_id"]).to eq(student.id.to_s)
    end

    it "links new user to an existing trainer record and sets role to personal" do
      trainer = create(:trainer, email: "joao@email.com")

      post "/api/v1/auth/google", params: { access_token: access_token }

      user = User.find_by(email: "joao@email.com")
      expect(user.trainer_id).to eq(trainer.id)
      expect(json_body["data"]["user"]["role"]).to eq("personal")
    end

    it "returns 401 for an invalid Google token" do
      allow(GoogleAuthService).to receive(:fetch_userinfo).and_return(nil)

      post "/api/v1/auth/google", params: { access_token: "bad-token" }

      expect(response).to have_http_status(:unauthorized)
      expect(json_body["error"]).to be_present
    end

    it "records an audit log on success" do
      expect do
        post "/api/v1/auth/google", params: { access_token: access_token }
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

  describe "PATCH /api/v1/auth/me" do
    it "lets an admin update their own name and email" do
      user = create(:user, :admin, name: "Old Name", email: "old@email.com")
      patch "/api/v1/auth/me", params: { name: "New Name", email: "new@email.com" },
                                headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(json_body["data"]["name"]).to eq("New Name")
      expect(json_body["data"]["email"]).to eq("new@email.com")
      expect(user.reload.name).to eq("New Name")
    end

    it "lets a personal update their own name and email" do
      user = create(:user, :personal)
      patch "/api/v1/auth/me", params: { name: "Personal Renamed" }, headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(user.reload.name).to eq("Personal Renamed")
    end

    it "lets a student update their own name and email" do
      user = create(:user, :student_account)
      patch "/api/v1/auth/me", params: { name: "Student Renamed" }, headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(user.reload.name).to eq("Student Renamed")
    end

    it "rejects a duplicate e-mail" do
      create(:user, :admin, email: "taken@email.com")
      user = create(:user, :personal)
      patch "/api/v1/auth/me", params: { email: "taken@email.com" }, headers: auth_headers(user)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "ignores an attempt to change role or associations" do
      user = create(:user, :student_account)
      other_trainer = create(:trainer)
      patch "/api/v1/auth/me", params: { role: "admin", trainer_id: other_trainer.id },
                                headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(user.reload.role).to eq("student")
      expect(user.trainer_id).to be_nil
    end

    it "rejects requests without a token" do
      patch "/api/v1/auth/me", params: { name: "No Auth" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PATCH /api/v1/auth/password" do
    let(:new_password) { "N3w@Str0ngPass" }

    it "lets an admin change their own password" do
      user = create(:user, :admin, password: "Str0ng@Pass")
      patch "/api/v1/auth/password",
            params: { current_password: "Str0ng@Pass", password: new_password,
                      password_confirmation: new_password },
            headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(user.reload.authenticate(new_password)).to be_truthy
    end

    it "lets a personal change their own password" do
      user = create(:user, :personal, password: "Str0ng@Pass")
      patch "/api/v1/auth/password",
            params: { current_password: "Str0ng@Pass", password: new_password,
                      password_confirmation: new_password },
            headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(user.reload.authenticate(new_password)).to be_truthy
    end

    it "lets a student change their own password" do
      user = create(:user, :student_account, password: "Str0ng@Pass")
      patch "/api/v1/auth/password",
            params: { current_password: "Str0ng@Pass", password: new_password,
                      password_confirmation: new_password },
            headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(user.reload.authenticate(new_password)).to be_truthy
    end

    it "rejects a wrong current password" do
      user = create(:user, :admin, password: "Str0ng@Pass")
      patch "/api/v1/auth/password",
            params: { current_password: "wrong-password", password: new_password,
                      password_confirmation: new_password },
            headers: auth_headers(user)

      expect(response).to have_http_status(:unauthorized)
      expect(user.reload.authenticate("Str0ng@Pass")).to be_truthy
    end

    it "rejects a weak new password" do
      user = create(:user, :admin, password: "Str0ng@Pass")
      patch "/api/v1/auth/password",
            params: { current_password: "Str0ng@Pass", password: "short",
                      password_confirmation: "short" },
            headers: auth_headers(user)

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.reload.authenticate("Str0ng@Pass")).to be_truthy
    end

    it "rejects a mismatched password confirmation" do
      user = create(:user, :admin, password: "Str0ng@Pass")
      patch "/api/v1/auth/password",
            params: { current_password: "Str0ng@Pass", password: new_password,
                      password_confirmation: "Different@123" },
            headers: auth_headers(user)

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.reload.authenticate("Str0ng@Pass")).to be_truthy
    end

    it "rejects requests without a token" do
      patch "/api/v1/auth/password",
            params: { current_password: "Str0ng@Pass", password: new_password,
                      password_confirmation: new_password }
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
