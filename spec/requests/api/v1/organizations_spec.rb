require "rails_helper"

RSpec.describe "Api::V1::Organizations", type: :request do
  let(:admin) { create(:user, :admin) }

  describe "GET /api/v1/organizations" do
    it "lists organizations without requiring authentication" do
      create(:organization, name: "Zebra Clinic")
      create(:organization, name: "Acme Clinic")

      get "/api/v1/organizations"

      expect(response).to have_http_status(:ok)
      names = json_body["data"].map { |o| o["name"] }
      expect(names).to eq([ "Acme Clinic", "Zebra Clinic" ])
    end

    it "only exposes id, name and domain" do
      create(:organization, name: "Acme Clinic", domain: "acme")

      get "/api/v1/organizations"

      expect(json_body["data"].first.keys).to contain_exactly("id", "name", "domain")
    end

    it "also works when called by an authenticated user" do
      get "/api/v1/organizations", headers: auth_headers(admin)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /api/v1/organizations/:id" do
    it "updates the admin's own organization" do
      patch "/api/v1/organizations/#{admin.organization_id}",
            params: { name: "Renamed Clinic", domain: "renamed-clinic" },
            headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(json_body["data"]).to include("name" => "Renamed Clinic", "domain" => "renamed-clinic")
      expect(admin.organization.reload.name).to eq("Renamed Clinic")
    end

    it "records an audit log on update" do
      expect do
        patch "/api/v1/organizations/#{admin.organization_id}",
              params: { name: "Renamed Clinic" },
              headers: auth_headers(admin)
      end.to change(AuditLog, :count).by(1)
      expect(AuditLog.last.action).to eq("organization.update")
    end

    it "forbids a non-admin from updating the organization" do
      personal = create(:user, :personal)
      patch "/api/v1/organizations/#{personal.organization_id}",
            params: { name: "Renamed Clinic" },
            headers: auth_headers(personal)

      expect(response).to have_http_status(:forbidden)
    end

    it "forbids an admin from updating another organization" do
      other_org = create(:organization)
      patch "/api/v1/organizations/#{other_org.id}",
            params: { name: "Renamed Clinic" },
            headers: auth_headers(admin)

      expect(response).to have_http_status(:forbidden)
      expect(other_org.reload.name).not_to eq("Renamed Clinic")
    end

    it "returns 422 for an invalid domain" do
      patch "/api/v1/organizations/#{admin.organization_id}",
            params: { domain: "Not A Valid Domain!" },
            headers: auth_headers(admin)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects an unauthenticated request" do
      patch "/api/v1/organizations/#{admin.organization_id}", params: { name: "Renamed Clinic" }
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
