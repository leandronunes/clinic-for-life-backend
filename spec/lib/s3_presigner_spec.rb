require "rails_helper"

RSpec.describe S3Presigner do
  let(:presigner) { described_class.new }
  let(:fake_presigned_url) { "https://bucket.s3.amazonaws.com/key?X-Amz-Signature=abc" }
  let(:fake_s3_presigner) { instance_double(Aws::S3::Presigner) }
  let(:fake_s3_client)    { instance_double(Aws::S3::Client) }

  before do
    stub_const("ENV", ENV.to_h.merge(
      "S3_BUCKET"              => "clinic-for-life",
      "AWS_REGION"             => "us-east-1",
      "AWS_ACCESS_KEY_ID"      => "test-key",
      "AWS_SECRET_ACCESS_KEY"  => "test-secret"
    ))
    allow(Aws::S3::Client).to receive(:new).and_return(fake_s3_client)
    allow(Aws::S3::Presigner).to receive(:new).and_return(fake_s3_presigner)
    allow(fake_s3_presigner).to receive(:presigned_url).and_return(fake_presigned_url)
  end

  describe "#presign" do
    subject(:result) do
      presigner.presign(content_type: "image/jpeg", context: "evolution_photo", student_id: "42")
    end

    it "returns an upload_url and a public_url" do
      expect(result).to include(:upload_url, :public_url)
    end

    it "uses uploads/students/:id/:context/ path in test environment" do
      expect(result[:public_url]).to match(%r{uploads/students/42/evolution_photo/})
    end

    it "does NOT add a dev/ prefix in test environment" do
      expect(result[:public_url]).not_to start_with("https://clinic-for-life.s3.us-east-1.amazonaws.com/dev/")
    end

    context "when Rails.env is development" do
      before { allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development")) }

      it "prefixes the key with dev/" do
        expect(result[:public_url]).to match(%r{\.amazonaws\.com/dev/uploads/students/42/evolution_photo/})
      end

      it "passes the prefixed key to the presigner" do
        result
        expect(fake_s3_presigner).to have_received(:presigned_url).with(
          :put_object,
          hash_including(key: match(%r{^dev/uploads/students/42/evolution_photo/}))
        )
      end
    end
  end

  describe "#presign without a student_id" do
    subject(:result) do
      presigner.presign(content_type: "image/jpeg", context: "partner_logo")
    end

    it "returns an upload_url and a public_url" do
      expect(result).to include(:upload_url, :public_url)
    end

    it "uses uploads/:context/ path, without a students/ segment" do
      expect(result[:public_url]).to match(%r{uploads/partner_logo/})
      expect(result[:public_url]).not_to include("students")
    end
  end

  describe "#presign_get_for" do
    let(:our_bucket_url) do
      "https://clinic-for-life.s3.us-east-1.amazonaws.com/uploads/students/7/exercise_video/abc.mp4"
    end

    it "presigns a URL pointing at our own bucket" do
      result = presigner.presign_get_for(our_bucket_url)

      expect(result).to eq(fake_presigned_url)
      expect(fake_s3_presigner).to have_received(:presigned_url).with(
        :get_object,
        hash_including(key: "uploads/students/7/exercise_video/abc.mp4")
      )
    end

    it "uses the GET expiry, not the upload expiry" do
      stub_const("ENV", ENV.to_h.merge("S3_GET_PRESIGN_EXPIRY" => "120"))
      presigner.presign_get_for(our_bucket_url)

      expect(fake_s3_presigner).to have_received(:presigned_url).with(
        :get_object,
        hash_including(expires_in: 120)
      )
    end

    it "defaults to 900 seconds when S3_GET_PRESIGN_EXPIRY is not set" do
      presigner.presign_get_for(our_bucket_url)

      expect(fake_s3_presigner).to have_received(:presigned_url).with(
        :get_object,
        hash_including(expires_in: 900)
      )
    end

    it "returns nil unchanged" do
      expect(presigner.presign_get_for(nil)).to be_nil
      expect(fake_s3_presigner).not_to have_received(:presigned_url)
    end

    it "returns a blank string unchanged" do
      expect(presigner.presign_get_for("")).to eq("")
      expect(fake_s3_presigner).not_to have_received(:presigned_url)
    end

    it "leaves a YouTube URL untouched" do
      youtube_url = "https://www.youtube.com/embed/abc123"
      expect(presigner.presign_get_for(youtube_url)).to eq(youtube_url)
      expect(fake_s3_presigner).not_to have_received(:presigned_url)
    end

    it "leaves a URL from a different bucket untouched" do
      other_url = "https://some-other-bucket.s3.us-east-1.amazonaws.com/uploads/x.jpg"
      expect(presigner.presign_get_for(other_url)).to eq(other_url)
      expect(fake_s3_presigner).not_to have_received(:presigned_url)
    end

    it "returns the URL unchanged when S3 is not configured" do
      stub_const("ENV", ENV.to_h.except("S3_BUCKET"))
      expect(presigner.presign_get_for(our_bucket_url)).to eq(our_bucket_url)
    end
  end

  describe ".presign_get_for" do
    it "delegates to a new instance's #presign_get_for" do
      url = "https://clinic-for-life.s3.us-east-1.amazonaws.com/uploads/x.jpg"
      result = described_class.presign_get_for(url)

      expect(result).to eq(fake_presigned_url)
    end
  end
end
