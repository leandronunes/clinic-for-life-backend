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

  INBODY_HEADERS = "data,Equipamento de medição,Peso(kg),Massa Muscular(kg),Soft Lean Mass(kg)," \
                   "Massa Gorda(kg),IMC(kg/m²),Gordura Corporal(%),Basal Metabolic Rate(kcal)," \
                   "InBody Score,Nível de Gordura Visceral(Level),Área de gordura visceral(cm²)"

  def inbody_row(date:, weight:, muscle: "-", fat_pct: "-", bmi: "-", visceral: "-")
    "#{date},H30,#{weight},#{muscle},-,-,#{bmi},#{fat_pct},1776,71,#{visceral},-"
  end

  let(:valid_csv) do
    [
      INBODY_HEADERS,
      inbody_row(date: "20260602173120", weight: "91.6", muscle: "36.8", fat_pct: "28.9", bmi: "28.9", visceral: "11")
    ].join("\n")
  end

  describe "POST /api/v1/bioimpedance/import" do
    it "imports a valid InBody row and returns preview" do
      expect do
        post "/api/v1/bioimpedance/import",
             params: { file: csv_upload(valid_csv), student_id: student.id },
             headers: auth_headers(personal)
      end.to change(BioimpedanceMeasurement, :count).by(1)

      expect(response).to have_http_status(:created)
      data = json_body["data"]
      expect(data["imported"]).to eq(1)
      expect(data["errors"]).to be_empty
      expect(data["preview"].first).to include(
        "weight_kg"      => 91.6,
        "muscle_mass_kg" => 36.8,
        "fat_percentage" => 28.9,
        "bmi"            => 28.9
      )
    end

    it "parses the date from the YYYYMMDDHHMMSS timestamp" do
      post "/api/v1/bioimpedance/import",
           params: { file: csv_upload(valid_csv), student_id: student.id },
           headers: auth_headers(personal)

      expect(student.bioimpedance_measurements.last.measured_on).to eq(Date.new(2026, 6, 2))
    end

    it "stores the visceral fat level" do
      post "/api/v1/bioimpedance/import",
           params: { file: csv_upload(valid_csv), student_id: student.id },
           headers: auth_headers(personal)

      expect(student.bioimpedance_measurements.last.visceral_fat).to eq(11)
    end

    it "treats dash values as nil" do
      csv = [ INBODY_HEADERS, inbody_row(date: "20260603000000", weight: "90.0") ].join("\n")
      post "/api/v1/bioimpedance/import",
           params: { file: csv_upload(csv), student_id: student.id },
           headers: auth_headers(personal)

      m = student.bioimpedance_measurements.last
      expect(m.muscle_mass_kg).to be_nil
      expect(m.fat_percentage).to be_nil
      expect(m.bmi).to be_nil
    end

    it "skips a duplicate date and reports it as an error" do
      create(:bioimpedance_measurement, student: student, measured_on: "2026-06-02")
      post "/api/v1/bioimpedance/import",
           params: { file: csv_upload(valid_csv), student_id: student.id },
           headers: auth_headers(personal)

      data = json_body["data"]
      expect(data["imported"]).to eq(0)
      expect(data["errors"].first).to match(/already been taken/)
    end

    it "returns 422 when student is not found" do
      post "/api/v1/bioimpedance/import",
           params: { file: csv_upload(valid_csv), student_id: 0 },
           headers: auth_headers(personal)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 403 when personal tries to import for another trainer's student" do
      other = create(:student)
      post "/api/v1/bioimpedance/import",
           params: { file: csv_upload(valid_csv), student_id: other.id },
           headers: auth_headers(personal)

      expect(response).to have_http_status(:forbidden)
    end

    it "returns 422 for a CSV that is not InBody format" do
      post "/api/v1/bioimpedance/import",
           params: { file: csv_upload("foo,bar\n1,2\n"), student_id: student.id },
           headers: auth_headers(personal)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 422 when no file is sent" do
      post "/api/v1/bioimpedance/import",
           params: { student_id: student.id },
           headers: auth_headers(personal)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "forbids students from importing" do
      student_user = create(:user, :student_account, student: student)
      post "/api/v1/bioimpedance/import",
           params: { file: csv_upload(valid_csv), student_id: student.id },
           headers: auth_headers(student_user)

      expect(response).to have_http_status(:forbidden)
    end

    it "requires authentication" do
      post "/api/v1/bioimpedance/import",
           params: { file: csv_upload(valid_csv), student_id: student.id }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
