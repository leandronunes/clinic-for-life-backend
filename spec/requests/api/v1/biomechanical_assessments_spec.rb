require "rails_helper"

RSpec.describe "Api::V1::BiomechanicalAssessments", type: :request do
  let(:trainer) { create(:trainer) }
  let(:personal) { create(:user, :personal, trainer: trainer) }
  let(:student) { create(:student, trainer: trainer) }

  describe "GET .../current" do
    it "returns (creating if needed) the current assessment" do
      expect do
        get "/api/v1/students/#{student.id}/biomechanical_assessments/current",
            headers: auth_headers(personal)
      end.to change(BiomechanicalAssessment, :count).by(1)
      expect(json_body["data"]["images"]).to eq({})
    end
  end

  describe "GET .../biomechanical_assessments" do
    it "lists the assessment history" do
      create(:biomechanical_assessment, student: student)
      get "/api/v1/students/#{student.id}/biomechanical_assessments", headers: auth_headers(personal)
      expect(json_body["data"].size).to eq(1)
    end
  end

  describe "POST .../new_assessment" do
    it "creates a new assessment" do
      expect do
        post "/api/v1/students/#{student.id}/biomechanical_assessments/new_assessment",
             headers: auth_headers(personal)
      end.to change(BiomechanicalAssessment, :count).by(1)
      expect(response).to have_http_status(:created)
    end
  end

  describe "PUT .../upload" do
    it "stores an image url in a valid slot" do
      put "/api/v1/students/#{student.id}/biomechanical_assessments/upload",
          params: { slot: "frontal", image_url: "https://example.com/f.jpg" },
          headers: auth_headers(personal)
      expect(response).to have_http_status(:ok)
      expect(json_body["data"]["images"]["frontal"]).to eq("https://example.com/f.jpg")
    end

    it "rejects an invalid slot" do
      put "/api/v1/students/#{student.id}/biomechanical_assessments/upload",
          params: { slot: "invalid", image_url: "https://example.com/x.jpg" },
          headers: auth_headers(personal)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "does not call S3 when uploading to an empty slot" do
      expect(S3Presigner).not_to receive(:new)

      put "/api/v1/students/#{student.id}/biomechanical_assessments/upload",
          params: { slot: "frontal", image_url: "https://clinic-bucket.s3.us-east-1.amazonaws.com/new.jpg" },
          headers: auth_headers(personal)
    end

    context "when replacing an existing S3 image" do
      let(:old_s3_url) { "https://clinic-bucket.s3.us-east-1.amazonaws.com/frontal-old.jpg" }
      let(:new_s3_url) { "https://clinic-bucket.s3.us-east-1.amazonaws.com/frontal-new.jpg" }

      before do
        assessment = create(:biomechanical_assessment, student: student)
        create(:biomechanical_image, biomechanical_assessment: assessment,
               slot: "frontal", image_url: old_s3_url)
      end

      it "calls S3Presigner to delete the old image" do
        presigner = instance_double(S3Presigner)
        allow(S3Presigner).to receive(:new).and_return(presigner)
        allow(presigner).to receive(:delete)

        put "/api/v1/students/#{student.id}/biomechanical_assessments/upload",
            params: { slot: "frontal", image_url: new_s3_url },
            headers: auth_headers(personal)

        expect(presigner).to have_received(:delete).with(public_url: old_s3_url)
      end

      it "returns 200 even if S3 deletion raises an error" do
        allow_any_instance_of(S3Presigner).to receive(:delete)
          .and_raise(Aws::S3::Errors::NoSuchKey.new({}, ""))

        put "/api/v1/students/#{student.id}/biomechanical_assessments/upload",
            params: { slot: "frontal", image_url: new_s3_url },
            headers: auth_headers(personal)

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "DELETE .../remove_image" do
    it "removes an image from a slot" do
      assessment = create(:biomechanical_assessment, student: student)
      create(:biomechanical_image, biomechanical_assessment: assessment, slot: "frontal")

      delete "/api/v1/students/#{student.id}/biomechanical_assessments/remove_image",
             params: { slot: "frontal" }, headers: auth_headers(personal)
      expect(json_body["data"]["images"]).not_to have_key("frontal")
    end
  end
end
