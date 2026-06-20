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
end
