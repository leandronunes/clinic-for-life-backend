require "rails_helper"

RSpec.describe EvolutionPhoto, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:student) }
    it { is_expected.to belong_to(:bioimpedance_measurement).optional }
  end

  describe "validations" do
    subject { build(:evolution_photo) }

    it { is_expected.to validate_presence_of(:taken_on) }
    it { is_expected.to validate_presence_of(:image_url) }

    it "rejects a duplicate bioimpedance_measurement_id" do
      measurement = create(:bioimpedance_measurement)
      create(:evolution_photo, bioimpedance_measurement: measurement)
      dup = build(:evolution_photo, bioimpedance_measurement: measurement)
      expect(dup).not_to be_valid
      expect(dup.errors[:bioimpedance_measurement_id]).to be_present
    end
  end

  describe "S3 cleanup on destroy" do
    it "deletes the S3 object when the record is destroyed" do
      s3_url = "https://clinic-bucket.s3.us-east-1.amazonaws.com/photo.jpg"
      photo = create(:evolution_photo, image_url: s3_url)
      s3 = instance_double(S3Presigner, delete: nil)
      allow(S3Presigner).to receive(:new).and_return(s3)

      photo.destroy!

      expect(s3).to have_received(:delete).with(public_url: s3_url)
    end

    it "does not call S3 for non-S3 URLs" do
      photo = create(:evolution_photo, image_url: "https://example.com/photo.jpg")
      expect(S3Presigner).not_to receive(:new)

      photo.destroy!
    end
  end
end
