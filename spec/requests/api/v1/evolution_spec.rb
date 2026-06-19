require "rails_helper"

RSpec.describe "Api::V1::Evolution & Bioimpedance", type: :request do
  let(:trainer) { create(:trainer) }
  let(:personal) { create(:user, :personal, trainer: trainer) }
  let(:student) { create(:student, trainer: trainer) }

  describe "GET .../evolution" do
    it "returns measurements ordered by date" do
      create(:bioimpedance_measurement, student: student, measured_on: "2025-02-01")
      create(:bioimpedance_measurement, student: student, measured_on: "2025-01-01")
      get "/api/v1/students/#{student.id}/evolution", headers: auth_headers(personal)
      dates = json_body["data"].map { |m| m["measured_on"] }
      expect(dates).to eq([ "2025-01-01", "2025-02-01" ])
    end

    it "includes photo_url when a photo is linked" do
      measurement = create(:bioimpedance_measurement, student: student)
      create(:evolution_photo, bioimpedance_measurement: measurement)
      get "/api/v1/students/#{student.id}/evolution", headers: auth_headers(personal)
      record = json_body["data"].first
      expect(record["photo_url"]).to eq("https://example.com/photo.jpg")
      expect(record["photo_id"]).to be_present
    end

    it "returns null photo_url when no photo is linked" do
      create(:bioimpedance_measurement, student: student)
      get "/api/v1/students/#{student.id}/evolution", headers: auth_headers(personal)
      expect(json_body["data"].first["photo_url"]).to be_nil
    end
  end

  describe "GET .../evolution/photos" do
    it "returns evolution photos" do
      measurement = create(:bioimpedance_measurement, student: student)
      create(:evolution_photo, bioimpedance_measurement: measurement)
      get "/api/v1/students/#{student.id}/evolution/photos", headers: auth_headers(personal)
      expect(json_body["data"].size).to eq(1)
      expect(json_body["data"].first).to include("image_url", "measurement_id", "taken_on")
    end
  end

  describe "POST .../evolution/photos" do
    let(:measurement) { create(:bioimpedance_measurement, student: student, measured_on: "2025-06-01") }
    let(:valid_params) do
      { bioimpedance_measurement_id: measurement.id, image_url: "https://s3.example.com/photo.jpg" }
    end

    it "creates a photo linked to the measurement and returns 201" do
      expect do
        post "/api/v1/students/#{student.id}/evolution/photos",
             params: valid_params, headers: auth_headers(personal)
      end.to change(EvolutionPhoto, :count).by(1)
      expect(response).to have_http_status(:created)
      expect(json_body["data"]["taken_on"]).to eq("2025-06-01")
      expect(json_body["data"]["measurement_id"]).to eq(measurement.id.to_s)
    end

    it "derives taken_on from the measurement date" do
      post "/api/v1/students/#{student.id}/evolution/photos",
           params: valid_params, headers: auth_headers(personal)
      expect(EvolutionPhoto.last.taken_on.iso8601).to eq("2025-06-01")
    end

    it "rejects when measurement does not belong to this student" do
      other_student = create(:student, trainer: trainer)
      other_measurement = create(:bioimpedance_measurement, student: other_student)
      post "/api/v1/students/#{student.id}/evolution/photos",
           params: { bioimpedance_measurement_id: other_measurement.id, image_url: "https://s3.example.com/p.jpg" },
           headers: auth_headers(personal)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rejects when the measurement already has a photo" do
      create(:evolution_photo, bioimpedance_measurement: measurement)
      post "/api/v1/students/#{student.id}/evolution/photos",
           params: valid_params, headers: auth_headers(personal)
      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body["error"]).to include("já possui uma foto")
    end

    it "rejects when image_url is missing" do
      post "/api/v1/students/#{student.id}/evolution/photos",
           params: { bioimpedance_measurement_id: measurement.id },
           headers: auth_headers(personal)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "DELETE .../evolution/photos/:id" do
    let(:measurement) { create(:bioimpedance_measurement, student: student) }
    let!(:photo) do
      create(:evolution_photo, bioimpedance_measurement: measurement,
             image_url: "https://clinic-bucket.s3.us-east-1.amazonaws.com/uploads/photo.jpg")
    end

    before do
      allow_any_instance_of(S3Presigner).to receive(:delete)
    end

    it "deletes the photo record and returns 204" do
      expect do
        delete "/api/v1/students/#{student.id}/evolution/photos/#{photo.id}",
               headers: auth_headers(personal)
      end.to change(EvolutionPhoto, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end

    it "calls S3Presigner to remove the S3 object" do
      presigner = instance_double(S3Presigner)
      allow(S3Presigner).to receive(:new).and_return(presigner)
      allow(presigner).to receive(:delete)

      delete "/api/v1/students/#{student.id}/evolution/photos/#{photo.id}",
             headers: auth_headers(personal)

      expect(presigner).to have_received(:delete).with(public_url: photo.image_url)
    end

    it "returns 204 even when S3 deletion raises an error" do
      allow_any_instance_of(S3Presigner).to receive(:delete).and_raise(Aws::S3::Errors::NoSuchKey.new({}, ""))

      delete "/api/v1/students/#{student.id}/evolution/photos/#{photo.id}",
             headers: auth_headers(personal)

      expect(response).to have_http_status(:no_content)
    end

    it "returns 404 when photo does not belong to this student" do
      other_student = create(:student, trainer: trainer)
      other_measurement = create(:bioimpedance_measurement, student: other_student)
      other_photo = create(:evolution_photo, bioimpedance_measurement: other_measurement)
      delete "/api/v1/students/#{student.id}/evolution/photos/#{other_photo.id}",
             headers: auth_headers(personal)
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for a non-existent photo id" do
      delete "/api/v1/students/#{student.id}/evolution/photos/0",
             headers: auth_headers(personal)
      expect(response).to have_http_status(:not_found)
    end

    it "returns 401 for unauthenticated requests" do
      delete "/api/v1/students/#{student.id}/evolution/photos/#{photo.id}"
      expect(response).to have_http_status(:unauthorized)
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
