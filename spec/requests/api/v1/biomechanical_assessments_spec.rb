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
      expect_any_instance_of(S3Presigner).not_to receive(:delete)

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
        # The response re-serializes the assessment's images map, which
        # presigns each URL — unrelated to the deletion behavior tested here.
        # Params canonicalization is a passthrough here too — new_s3_url is
        # already canonical.
        allow(presigner).to receive(:presign_get_for) { |url| url }
        allow(presigner).to receive(:canonicalize) { |url| url }

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

    context "when the client echoes back the presigned form of the current image_url" do
      # Same class of bug as exercises_spec's "echoes back the presigned form
      # of the current video_url": the frontend's slot preview is fed from a
      # presigned GET response (BiomechanicalAssessmentSerializer), so a
      # naive re-upload of "the same slot" could send that presigned string
      # back — same S3 object, different literal string.
      let(:canonical_url) { "https://clinic-bucket.s3.us-east-1.amazonaws.com/frontal-old.jpg" }
      let(:presigned_url_for_same_object) do
        "#{canonical_url}?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Expires=900&X-Amz-Signature=abc"
      end

      before do
        stub_const("ENV", ENV.to_h.merge("S3_BUCKET" => "clinic-bucket", "AWS_REGION" => "us-east-1"))
        # The response re-serializes the assessment's images map, which
        # presigns each URL — stub it to a passthrough so this doesn't need
        # real AWS credentials. #canonicalize is deliberately left
        # un-stubbed: it's what this context verifies, and it never calls
        # out to AWS (pure URI parsing).
        allow_any_instance_of(S3Presigner).to receive(:presign_get_for) { |_instance, url, **_kwargs| url }
        assessment = create(:biomechanical_assessment, student: student)
        create(:biomechanical_image, biomechanical_assessment: assessment,
               slot: "frontal", image_url: canonical_url)
      end

      it "does not delete the S3 object, since it's still referenced" do
        expect_any_instance_of(S3Presigner).not_to receive(:delete)

        put "/api/v1/students/#{student.id}/biomechanical_assessments/upload",
            params: { slot: "frontal", image_url: presigned_url_for_same_object },
            headers: auth_headers(personal)
      end

      it "persists the canonical URL, not the presigned one with its query string" do
        put "/api/v1/students/#{student.id}/biomechanical_assessments/upload",
            params: { slot: "frontal", image_url: presigned_url_for_same_object },
            headers: auth_headers(personal)

        image = BiomechanicalImage.find_by(slot: "frontal")
        expect(image.image_url).to eq(canonical_url)
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
