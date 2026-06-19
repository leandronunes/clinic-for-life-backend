require "rails_helper"

RSpec.describe Exam, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:student) }
  end

  describe "validations" do
    subject { build(:exam) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:file_url) }
  end

  describe "uploaded_at default" do
    it "sets uploaded_at automatically when blank" do
      exam = create(:exam, uploaded_at: nil)
      expect(exam.uploaded_at).to be_present
    end

    it "keeps a provided uploaded_at" do
      timestamp = 2.days.ago.change(usec: 0)
      exam = create(:exam, uploaded_at: timestamp)
      expect(exam.uploaded_at).to be_within(1.second).of(timestamp)
    end
  end

  describe "S3 cleanup on destroy" do
    it "deletes the S3 object when the record is destroyed" do
      s3_url = "https://clinic-bucket.s3.us-east-1.amazonaws.com/exam.pdf"
      exam = create(:exam, file_url: s3_url)
      s3 = instance_double(S3Presigner, delete: nil)
      allow(S3Presigner).to receive(:new).and_return(s3)

      exam.destroy!

      expect(s3).to have_received(:delete).with(public_url: s3_url)
    end

    it "does not call S3 for non-S3 URLs" do
      exam = create(:exam, file_url: "https://example.com/exam.pdf")
      expect(S3Presigner).not_to receive(:new)

      exam.destroy!
    end
  end
end
