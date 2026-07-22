require "rails_helper"

RSpec.describe "Api::V1::Organizations", type: :request do
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
      admin = create(:user, :admin)
      get "/api/v1/organizations", headers: auth_headers(admin)
      expect(response).to have_http_status(:ok)
    end
  end
end
