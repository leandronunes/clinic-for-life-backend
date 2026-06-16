require "rails_helper"

RSpec.describe "Api::V1::Evolution & Bioimpedance", type: :request do
  let(:trainer) { create(:trainer) }
  let(:personal) { create(:user, :personal, trainer: trainer) }
  let(:student) { create(:student, trainer: trainer, height_cm: 170) }

  describe "GET .../evolution" do
    it "returns measurements ordered by date" do
      create(:bioimpedance_measurement, student: student, measured_on: "2025-02-01")
      create(:bioimpedance_measurement, student: student, measured_on: "2025-01-01")
      get "/api/v1/students/#{student.id}/evolution", headers: auth_headers(personal)
      dates = json_body["data"].map { |m| m["measured_on"] }
      expect(dates).to eq([ "2025-01-01", "2025-02-01" ])
    end
  end

  describe "GET .../evolution/photos" do
    it "returns evolution photos" do
      create(:evolution_photo, student: student)
      get "/api/v1/students/#{student.id}/evolution/photos", headers: auth_headers(personal)
      expect(json_body["data"].size).to eq(1)
    end
  end

  describe "POST .../bioimpedance_measurements" do
    it "creates a manual measurement" do
      expect do
        post "/api/v1/students/#{student.id}/bioimpedance_measurements",
             params: { weight_kg: 68, measured_on: "2025-03-01" }, headers: auth_headers(personal)
      end.to change(BioimpedanceMeasurement, :count).by(1)
      expect(response).to have_http_status(:created)
      expect(json_body["data"]["weight_kg"].to_f).to eq(68.0)
    end

    it "rejects an invalid measurement" do
      post "/api/v1/students/#{student.id}/bioimpedance_measurements",
           params: { weight_kg: -1, measured_on: "2025-03-01" }, headers: auth_headers(personal)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET .../bioimpedance_measurements" do
    it "lists measurements" do
      create(:bioimpedance_measurement, student: student)
      get "/api/v1/students/#{student.id}/bioimpedance_measurements", headers: auth_headers(personal)
      expect(json_body["data"].size).to eq(1)
    end
  end
end
