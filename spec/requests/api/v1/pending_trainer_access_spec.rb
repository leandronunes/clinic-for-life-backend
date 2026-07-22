require "rails_helper"

RSpec.describe "Pending trainer access gate", type: :request do
  let(:trainer) { create(:trainer, approved_at: nil) }
  let(:pending_user) { create(:user, :personal, trainer: trainer, organization: trainer.organization) }

  it "blocks a pending trainer from a normal endpoint with a distinguishable error code" do
    get "/api/v1/students", headers: auth_headers(pending_user)

    expect(response).to have_http_status(:forbidden)
    expect(json_body["code"]).to eq("pending_approval")
  end

  it "still allows a pending trainer to read their own profile" do
    get "/api/v1/auth/me", headers: auth_headers(pending_user)
    expect(response).to have_http_status(:ok)
  end

  it "still allows a pending trainer to update their own profile" do
    patch "/api/v1/auth/me", params: { name: "Updated" }, headers: auth_headers(pending_user)
    expect(response).to have_http_status(:ok)
  end

  it "still allows a pending trainer to change their password" do
    patch "/api/v1/auth/password",
          params: { current_password: "Str0ng@Pass", password: "N3wStr0ng@Pass",
                     password_confirmation: "N3wStr0ng@Pass" },
          headers: auth_headers(pending_user)

    expect(response).to have_http_status(:ok)
  end

  it "does not block an approved trainer" do
    approved_trainer = create(:trainer)
    approved_user = create(:user, :personal, trainer: approved_trainer, organization: approved_trainer.organization)
    get "/api/v1/students", headers: auth_headers(approved_user)

    expect(response).not_to have_http_status(:forbidden)
  end

  it "does not block admins or students" do
    admin = create(:user, :admin)
    get "/api/v1/students", headers: auth_headers(admin)
    expect(response).not_to have_http_status(:forbidden)

    student_user = create(:user, :student_account)
    get "/api/v1/students/#{student_user.student_id}", headers: auth_headers(student_user)
    expect(response).not_to have_http_status(:forbidden)
  end
end
