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

    it "creates a new student-role user with its own student profile, and returns a session token" do
      expect do
        post "/api/v1/auth/register", params: valid_params
      end.to change(User, :count).by(1).and change(Student, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json_body["data"]["token"]).to be_present
      expect(json_body["data"]["user"]["email"]).to eq("joao@email.com")
      expect(json_body["data"]["user"]["role"]).to eq("student")
      expect(json_body["data"]["user"]["student_id"]).to be_present

      student = Student.find(json_body["data"]["user"]["student_id"])
      expect(student.name).to eq("João Silva")
      expect(student.email).to eq("joao@email.com")
    end

    it "links the user to an existing student record with the same email, instead of creating a new one" do
      student = create(:student, email: "joao@email.com")

      expect do
        post "/api/v1/auth/register", params: valid_params
      end.not_to change(Student, :count)

      expect(response).to have_http_status(:created)
      user = User.find_by(email: "joao@email.com")
      expect(user.student_id).to eq(student.id)
      expect(json_body["data"]["user"]["student_id"]).to eq(student.id.to_s)
      expect(json_body["data"]["user"]["role"]).to eq("student")
    end

    it "lets the newly self-registered student access their own profile" do
      post "/api/v1/auth/register", params: valid_params
      user = User.find_by(email: "joao@email.com")

      get "/api/v1/students/#{user.student_id}", headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(json_body["data"]["id"]).to eq(user.student_id.to_s)
    end

    it "makes the newly self-registered student show up in the admin's student listing" do
      admin = create(:user, :admin)
      post "/api/v1/auth/register", params: valid_params
      user = User.find_by(email: "joao@email.com")

      get "/api/v1/students", headers: auth_headers(admin)

      expect(json_body["data"].map { |s| s["id"] }).to include(user.student_id.to_s)
    end

    it "gives two same-named students their own independent profiles, matched only by e-mail" do
      first_params = { name: "Ana Carolina", email: "ana@email.com",
                        password: "Str0ng@Pass", password_confirmation: "Str0ng@Pass" }
      second_params = { name: "Ana Carolina", email: "ana.carolina2@email.com",
                         password: "Str0ng@Pass", password_confirmation: "Str0ng@Pass" }

      post "/api/v1/auth/register", params: first_params
      first_user = User.find_by(email: "ana@email.com")
      post "/api/v1/auth/register", params: second_params
      second_user = User.find_by(email: "ana.carolina2@email.com")

      expect(first_user.student_id).to be_present
      expect(second_user.student_id).to be_present
      expect(second_user.student_id).not_to eq(first_user.student_id)

      # Each can access their own profile — and only their own.
      get "/api/v1/students/#{second_user.student_id}", headers: auth_headers(second_user)
      expect(response).to have_http_status(:ok)

      get "/api/v1/students/#{first_user.student_id}", headers: auth_headers(second_user)
      expect(response).to have_http_status(:forbidden)
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

    it "rejects a weak password, without leaving an orphaned student profile behind" do
      expect do
        post "/api/v1/auth/register", params: valid_params.merge(password: "weak",
                                                                 password_confirmation: "weak")
      end.not_to change(Student, :count)

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

    it "creates a new student-role user with its own student profile on first Google login" do
      expect do
        post "/api/v1/auth/google", params: { access_token: access_token }
      end.to change(User, :count).by(1).and change(Student, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json_body["data"]["token"]).to be_present
      expect(json_body["data"]["user"]["email"]).to eq("joao@email.com")
      expect(json_body["data"]["user"]["role"]).to eq("student")
      expect(json_body["data"]["user"]["student_id"]).to be_present
    end

    it "logs in an existing user without creating a new account" do
      existing = create(:user, :admin, email: "joao@email.com")

      expect do
        post "/api/v1/auth/google", params: { access_token: access_token }
      end.not_to change(User, :count)

      expect(response).to have_http_status(:ok)
      expect(json_body["data"]["user"]["id"]).to eq(existing.id.to_s)
    end

    it "links new user to an existing student record with the same email, instead of creating a new one" do
      student = create(:student, email: "joao@email.com")

      expect do
        post "/api/v1/auth/google", params: { access_token: access_token }
      end.not_to change(Student, :count)

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

  describe "POST /api/v1/auth/password/forgot" do
    it "generates a reset token and delivers the mailer for a matching e-mail" do
      user = create(:user, :admin, email: "forgot@forlife.app")

      expect do
        post "/api/v1/auth/password/forgot", params: { email: "forgot@forlife.app" }
      end.to have_enqueued_mail(PasswordResetMailer, :reset_instructions)

      expect(response).to have_http_status(:ok)
      expect(json_body["data"]["message"]).to be_present
      expect(user.reload.reset_password_token_digest).to be_present
    end

    it "is case-insensitive on the email" do
      create(:user, :admin, email: "forgot@forlife.app")

      expect do
        post "/api/v1/auth/password/forgot", params: { email: "FORGOT@forlife.app" }
      end.to have_enqueued_mail(PasswordResetMailer, :reset_instructions)
    end

    it "responds with the same generic message for an unknown e-mail, without sending anything" do
      expect do
        post "/api/v1/auth/password/forgot", params: { email: "ghost@forlife.app" }
      end.not_to have_enqueued_mail(PasswordResetMailer, :reset_instructions)

      expect(response).to have_http_status(:ok)
      expect(json_body["data"]["message"]).to be_present
    end

    it "does not reveal whether the e-mail exists — both responses are identical" do
      create(:user, :admin, email: "forgot@forlife.app")

      post "/api/v1/auth/password/forgot", params: { email: "forgot@forlife.app" }
      known_message = json_body["data"]["message"]

      post "/api/v1/auth/password/forgot", params: { email: "ghost@forlife.app" }
      unknown_message = json_body["data"]["message"]

      expect(known_message).to eq(unknown_message)
    end

    it "records an audit log only when the e-mail matches an account" do
      create(:user, :admin, email: "forgot@forlife.app")

      expect do
        post "/api/v1/auth/password/forgot", params: { email: "forgot@forlife.app" }
      end.to change(AuditLog, :count).by(1)

      expect do
        post "/api/v1/auth/password/forgot", params: { email: "ghost@forlife.app" }
      end.not_to change(AuditLog, :count)
    end

    it "overwrites a previous token when requested again" do
      user = create(:user, :admin, email: "forgot@forlife.app")

      post "/api/v1/auth/password/forgot", params: { email: "forgot@forlife.app" }
      first_digest = user.reload.reset_password_token_digest

      post "/api/v1/auth/password/forgot", params: { email: "forgot@forlife.app" }
      second_digest = user.reload.reset_password_token_digest

      expect(second_digest).not_to eq(first_digest)
    end
  end

  describe "POST /api/v1/auth/password/reset" do
    let(:user) { create(:user, :admin, email: "reset@forlife.app", password: "Old@Str0ngPass") }

    it "resets the password and signs the user in with a valid token" do
      raw_token = user.generate_password_reset_token!

      post "/api/v1/auth/password/reset",
           params: { token: raw_token, password: "N3w@Str0ngPass", password_confirmation: "N3w@Str0ngPass" }

      expect(response).to have_http_status(:ok)
      expect(json_body["data"]["token"]).to be_present
      expect(json_body["data"]["user"]["email"]).to eq("reset@forlife.app")
      expect(user.reload.authenticate("N3w@Str0ngPass")).to be_truthy
    end

    it "clears the reset token after a successful reset" do
      raw_token = user.generate_password_reset_token!

      post "/api/v1/auth/password/reset",
           params: { token: raw_token, password: "N3w@Str0ngPass", password_confirmation: "N3w@Str0ngPass" }

      expect(user.reload.reset_password_token_digest).to be_nil
    end

    it "rejects a token that does not exist" do
      post "/api/v1/auth/password/reset",
           params: { token: "not-a-real-token", password: "N3w@Str0ngPass",
                      password_confirmation: "N3w@Str0ngPass" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body["error"]).to be_present
    end

    it "rejects an expired token" do
      raw_token = user.generate_password_reset_token!
      user.update_column(:reset_password_sent_at, 31.minutes.ago)

      post "/api/v1/auth/password/reset",
           params: { token: raw_token, password: "N3w@Str0ngPass", password_confirmation: "N3w@Str0ngPass" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.reload.authenticate("N3w@Str0ngPass")).to be_falsy
    end

    it "rejects a weak new password, keeping the token valid for a retry" do
      raw_token = user.generate_password_reset_token!

      post "/api/v1/auth/password/reset",
           params: { token: raw_token, password: "weak", password_confirmation: "weak" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.reload.reset_password_token_digest).to be_present
    end

    it "cannot be reused after a successful reset" do
      raw_token = user.generate_password_reset_token!
      post "/api/v1/auth/password/reset",
           params: { token: raw_token, password: "N3w@Str0ngPass", password_confirmation: "N3w@Str0ngPass" }

      post "/api/v1/auth/password/reset",
           params: { token: raw_token, password: "An0ther@Pass", password_confirmation: "An0ther@Pass" }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "records an audit log on success" do
      raw_token = user.generate_password_reset_token!

      expect do
        post "/api/v1/auth/password/reset",
             params: { token: raw_token, password: "N3w@Str0ngPass", password_confirmation: "N3w@Str0ngPass" }
      end.to change(AuditLog, :count).by(1)
    end
  end
end
