require "rails_helper"

RSpec.describe "Api::V1::Partners", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:student_user) { create(:user, :student_account) }

  describe "GET /api/v1/partners" do
    it "lists partners for any authenticated user" do
      create_list(:partner, 2, organization: student_user.organization)
      get "/api/v1/partners", headers: auth_headers(student_user)
      expect(response).to have_http_status(:ok)
      expect(json_body["data"].size).to eq(2)
    end

    it "does not include partners from another organization for an authenticated user" do
      create(:partner, organization: student_user.organization)
      create(:partner) # different organization entirely
      get "/api/v1/partners", headers: auth_headers(student_user)
      expect(json_body["data"].size).to eq(1)
    end

    it "filters by category" do
      create(:partner, category: "Nutrition", organization: admin.organization)
      create(:partner, category: "Physiotherapy", organization: admin.organization)
      get "/api/v1/partners", params: { category: "Nutrition" }, headers: auth_headers(admin)
      expect(json_body["data"].size).to eq(1)
      expect(json_body["data"].map { |p| p["category"] }).to all(eq("Nutrition"))
    end

    it "allows unauthenticated access (public partner showcase)" do
      organization = create(:organization, domain: "academia-x")
      create_list(:partner, 2, organization: organization)
      get "/api/v1/partners", params: { domain: "academia-x" }
      expect(response).to have_http_status(:ok)
      expect(json_body["data"].size).to eq(2)
    end

    it "returns no partners for an unauthenticated request without a domain" do
      create_list(:partner, 2)

      get "/api/v1/partners"

      expect(response).to have_http_status(:ok)
      expect(json_body["data"]).to eq([])
    end

    it "filters the public showcase by the organization's domain" do
      organization = create(:organization, domain: "academia-x")
      create(:partner, organization: organization)
      create(:partner) # different organization entirely

      get "/api/v1/partners", params: { domain: "academia-x" }

      expect(json_body["data"].size).to eq(1)
    end

    it "matches the domain filter case-insensitively" do
      organization = create(:organization, domain: "academia-x")
      create(:partner, organization: organization)

      get "/api/v1/partners", params: { domain: "ACADEMIA-X" }

      expect(json_body["data"].size).to eq(1)
    end

    it "filters by a full hostname domain" do
      organization = create(:organization, domain: "academia1.clinicforlife.com.br")
      create(:partner, organization: organization)
      create(:partner) # different organization entirely

      get "/api/v1/partners", params: { domain: "academia1.clinicforlife.com.br" }

      expect(json_body["data"].size).to eq(1)
    end

    it "returns no partners for an unknown domain" do
      create_list(:partner, 2)

      get "/api/v1/partners", params: { domain: "no-such-domain" }

      expect(json_body["data"]).to eq([])
    end

    it "ignores the domain filter for an authenticated request (already org-scoped)" do
      create(:partner, organization: student_user.organization)
      other_organization = create(:organization)

      get "/api/v1/partners", params: { domain: other_organization.domain },
                               headers: auth_headers(student_user)

      expect(json_body["data"].size).to eq(1)
    end
  end

  describe "POST /api/v1/partners" do
    let(:params) { { name: "NutriVida", category: "Nutrition", link: "https://x.com" } }

    it "creates a partner as admin" do
      expect do
        post "/api/v1/partners", params: params, headers: auth_headers(admin)
      end.to change(Partner, :count).by(1)
      expect(response).to have_http_status(:created)
    end

    it "persists discount_details" do
      post "/api/v1/partners", params: params.merge(discount_details: "15% off"),
                                headers: auth_headers(admin)
      expect(json_body["data"]["discount_details"]).to eq("15% off")
    end

    it "persists discount_details for the reported NutriVida payload" do
      payload = {
        name: "NutriVida",
        logo_url: "https://clinic-for-life.s3.us-west-2.amazonaws.com/dev/uploads/partner_logo/25b9054c-65ad-473f-afbe-a8961cbb2d7e.jpg",
        category: "Nutrition",
        description: "Consultoria nutricional especializada em performance esportiva.",
        discount_details: "50% de desconto para teste",
        link: "https://example.com/nutrivida"
      }

      post "/api/v1/partners", params: payload, headers: auth_headers(admin)

      expect(response).to have_http_status(:created)
      expect(json_body["data"]["discount_details"]).to eq("50% de desconto para teste")
      expect(Partner.last.discount_details).to eq("50% de desconto para teste")
    end

    it "forbids a student from creating partners" do
      post "/api/v1/partners", params: params, headers: auth_headers(student_user)
      expect(response).to have_http_status(:forbidden)
    end

    it "accepts any free-text category" do
      post "/api/v1/partners", params: params.merge(category: "Odontologia"),
                                headers: auth_headers(admin)
      expect(response).to have_http_status(:created)
      expect(json_body["data"]["category"]).to eq("Odontologia")
    end

    it "rejects a blank category" do
      post "/api/v1/partners", params: params.merge(category: ""), headers: auth_headers(admin)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /api/v1/partners/:id" do
    it "updates a partner as admin" do
      partner = create(:partner, organization: admin.organization)
      patch "/api/v1/partners/#{partner.id}", params: { name: "Renamed" }, headers: auth_headers(admin)
      expect(partner.reload.name).to eq("Renamed")
    end

    it "updates discount_details" do
      partner = create(:partner, organization: admin.organization)
      patch "/api/v1/partners/#{partner.id}", params: { discount_details: "20% off" },
                                               headers: auth_headers(admin)
      expect(partner.reload.discount_details).to eq("20% off")
    end

    it "forbids an admin from updating a partner in another organization" do
      partner = create(:partner) # different organization entirely
      patch "/api/v1/partners/#{partner.id}", params: { name: "Renamed" }, headers: auth_headers(admin)
      expect(response).to have_http_status(:forbidden)
      expect(partner.reload.name).not_to eq("Renamed")
    end
  end

  describe "DELETE /api/v1/partners/:id" do
    it "deletes a partner as admin" do
      partner = create(:partner, organization: admin.organization)
      expect do
        delete "/api/v1/partners/#{partner.id}", headers: auth_headers(admin)
      end.to change(Partner, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end

    it "forbids an admin from deleting a partner in another organization" do
      partner = create(:partner) # different organization entirely
      delete "/api/v1/partners/#{partner.id}", headers: auth_headers(admin)
      expect(response).to have_http_status(:forbidden)
      expect(Partner.exists?(partner.id)).to be true
    end
  end
end
