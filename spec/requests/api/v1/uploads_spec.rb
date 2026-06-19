require "rails_helper"

RSpec.describe "Api::V1::Uploads", type: :request do
  let(:trainer)      { create(:trainer) }
  let(:personal)     { create(:user, :personal, trainer: trainer) }
  let(:admin)        { create(:user, :admin) }
  let(:student)      { create(:student, trainer: trainer) }
  let(:student_user) { create(:user, :student_account, student: student) }

  let(:fake_upload_url) { "https://clinic-for-life.s3.us-west-2.amazonaws.com/uploads/exercise_video/uuid.mp4?X-Amz-Signature=abc" }
  let(:fake_public_url) { "https://clinic-for-life.s3.us-west-2.amazonaws.com/uploads/exercise_video/uuid.mp4" }
  let(:presign_result)  { { upload_url: fake_upload_url, public_url: fake_public_url } }

  before do
    allow_any_instance_of(S3Presigner).to receive(:presign).and_return(presign_result)
  end

  describe "POST /api/v1/uploads/presign" do
    let(:valid_params) { { content_type: "video/mp4", context: "exercise_video" } }

    it "returns presigned URL for a personal trainer" do
      post "/api/v1/uploads/presign", params: valid_params, headers: auth_headers(personal)

      expect(response).to have_http_status(:ok)
      expect(json_body["data"]).to include("upload_url" => fake_upload_url, "public_url" => fake_public_url)
    end

    it "returns presigned URL for an admin" do
      post "/api/v1/uploads/presign", params: valid_params, headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(json_body["data"]).to include("upload_url", "public_url")
    end

    it "forbids students from generating presigned URLs" do
      post "/api/v1/uploads/presign", params: valid_params, headers: auth_headers(student_user)

      expect(response).to have_http_status(:forbidden)
    end

    it "requires authentication" do
      post "/api/v1/uploads/presign", params: valid_params

      expect(response).to have_http_status(:unauthorized)
    end

    context "with invalid content type" do
      before { allow_any_instance_of(S3Presigner).to receive(:presign).and_call_original }

      it "returns 422 for non-video content type" do
        post "/api/v1/uploads/presign",
             params: { content_type: "application/pdf", context: "exercise_video" },
             headers: auth_headers(personal)

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_body["error"]).to include("Content type not allowed")
      end

      it "returns 422 for unknown context" do
        post "/api/v1/uploads/presign",
             params: { content_type: "video/mp4", context: "unknown_context" },
             headers: auth_headers(personal)

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_body["error"]).to include("Context not allowed")
      end
    end

    context "when S3 is not configured" do
      before do
        allow_any_instance_of(S3Presigner).to receive(:presign)
          .and_raise(S3Presigner::ConfigurationError, "S3_BUCKET not configured")
      end

      it "returns 503" do
        post "/api/v1/uploads/presign", params: valid_params, headers: auth_headers(personal)

        expect(response).to have_http_status(:service_unavailable)
        expect(json_body["error"]).to eq("Storage not configured")
      end
    end
  end
end
