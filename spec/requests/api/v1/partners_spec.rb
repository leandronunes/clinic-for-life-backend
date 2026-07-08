require "rails_helper"

RSpec.describe "Api::V1::Partners", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:student_user) { create(:user, :student_account) }

  describe "GET /api/v1/partners" do
    it "lists partners for any authenticated user" do
      create_list(:partner, 2)
      get "/api/v1/partners", headers: auth_headers(student_user)
      expect(response).to have_http_status(:ok)
      expect(json_body["data"].size).to eq(2)
    end

    it "filters by category" do
      create(:partner, category: "Nutrition")
      create(:partner, category: "Physiotherapy")
      get "/api/v1/partners", params: { category: "Nutrition" }, headers: auth_headers(admin)
      expect(json_body["data"].map { |p| p["category"] }).to all(eq("Nutrition"))
    end

    it "allows unauthenticated access (public partner showcase)" do
      create_list(:partner, 2)
      get "/api/v1/partners"
      expect(response).to have_http_status(:ok)
      expect(json_body["data"].size).to eq(2)
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

    it "forbids a student from creating partners" do
      post "/api/v1/partners", params: params, headers: auth_headers(student_user)
      expect(response).to have_http_status(:forbidden)
    end

    it "rejects an invalid category" do
      post "/api/v1/partners", params: params.merge(category: "Bogus"), headers: auth_headers(admin)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /api/v1/partners/:id" do
    it "updates a partner as admin" do
      partner = create(:partner)
      patch "/api/v1/partners/#{partner.id}", params: { name: "Renamed" }, headers: auth_headers(admin)
      expect(partner.reload.name).to eq("Renamed")
    end

    it "updates discount_details" do
      partner = create(:partner)
      patch "/api/v1/partners/#{partner.id}", params: { discount_details: "20% off" },
                                               headers: auth_headers(admin)
      expect(partner.reload.discount_details).to eq("20% off")
    end
  end

  describe "DELETE /api/v1/partners/:id" do
    it "deletes a partner as admin" do
      partner = create(:partner)
      expect do
        delete "/api/v1/partners/#{partner.id}", headers: auth_headers(admin)
      end.to change(Partner, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end
  end
end
