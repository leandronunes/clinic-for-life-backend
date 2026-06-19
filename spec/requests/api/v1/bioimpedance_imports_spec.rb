require "rails_helper"
require "rack/test"

RSpec.describe "Api::V1::BioimpedanceImports", type: :request do
  let(:trainer) { create(:trainer) }
  let(:personal) { create(:user, :personal, trainer: trainer) }
  let!(:student) { create(:student, trainer: trainer, email: "julia@email.com") }

  def csv_upload(content)
    file = Tempfile.new([ "bio", ".csv" ])
    file.write(content)
    file.rewind
    Rack::Test::UploadedFile.new(file.path, "text/csv")
  end

  describe "POST /api/v1/bioimpedance/import" do
    it "imports valid rows and reports row-level errors" do
      content = <<~CSV
        student_email,measured_on,weight_kg,muscle_mass_kg,fat_percentage
        julia@email.com,2025-01-01,65.9,32.2,22.5
        nobody@email.com,2025-01-01,60,30,20
        julia@email.com,2025-01-02,-5,30,20
      CSV

      expect do
        post "/api/v1/bioimpedance/import",
             params: { file: csv_upload(content), filename: "bio.csv" },
             headers: auth_headers(personal)
      end.to change(BioimpedanceImport, :count).by(1)

      expect(response).to have_http_status(:created)
      data = json_body["data"]
      expect(data["total_rows"]).to eq(3)
      expect(data["imported_count"]).to eq(1)
      expect(data["errors"].size).to eq(2)
    end

    it "detects duplicate dates" do
      create(:bioimpedance_measurement, student: student, measured_on: "2025-01-01")
      content = <<~CSV
        student_email,measured_on,weight_kg
        julia@email.com,2025-01-01,70
      CSV
      post "/api/v1/bioimpedance/import",
           params: { file: csv_upload(content) }, headers: auth_headers(personal)

      expect(json_body["data"]["imported_count"]).to eq(0)
      expect(json_body["data"]["errors"].first["error"]).to match(/already been taken/)
    end

    it "rejects a CSV missing required headers" do
      content = "foo,bar\n1,2\n"
      post "/api/v1/bioimpedance/import",
           params: { file: csv_upload(content) }, headers: auth_headers(personal)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rejects a request with no file" do
      post "/api/v1/bioimpedance/import", headers: auth_headers(personal)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "blocks a personal from importing into another trainer's student" do
      other = create(:student, email: "other@email.com")
      content = <<~CSV
        student_email,measured_on,weight_kg
        other@email.com,2025-01-01,70
      CSV
      post "/api/v1/bioimpedance/import",
           params: { file: csv_upload(content) }, headers: auth_headers(personal)
      expect(json_body["data"]["errors"].first["error"]).to match(/Not authorized/)
      expect(other.bioimpedance_measurements).to be_empty
    end

    it "forbids a student from importing" do
      student_user = create(:user, :student_account, student: student)
      content = "student_email,measured_on,weight_kg\njulia@email.com,2025-01-01,70\n"
      post "/api/v1/bioimpedance/import",
           params: { file: csv_upload(content) }, headers: auth_headers(student_user)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
