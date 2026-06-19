require "rails_helper"

RSpec.describe BiomechanicalAssessment, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:student) }
    it { is_expected.to have_many(:biomechanical_images).dependent(:destroy) }
  end

  describe "#images_map" do
    it "maps each slot to its image url" do
      assessment = create(:biomechanical_assessment)
      create(:biomechanical_image, biomechanical_assessment: assessment,
             slot: "frontal", image_url: "https://example.com/f.jpg")
      create(:biomechanical_image, biomechanical_assessment: assessment,
             slot: "posterior", image_url: "https://example.com/p.jpg")

      expect(assessment.images_map).to eq(
        "frontal" => "https://example.com/f.jpg",
        "posterior" => "https://example.com/p.jpg"
      )
    end

    it "returns an empty hash with no images" do
      expect(create(:biomechanical_assessment).images_map).to eq({})
    end
  end
end

RSpec.describe BiomechanicalImage, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:biomechanical_assessment) }
  end

  describe "validations" do
    subject { build(:biomechanical_image) }

    it { is_expected.to validate_presence_of(:image_url) }
    it { is_expected.to validate_inclusion_of(:slot).in_array(BiomechanicalImage::SLOTS) }

    it "enforces a single image per slot within an assessment" do
      existing = create(:biomechanical_image)
      duplicate = build(:biomechanical_image,
                        biomechanical_assessment: existing.biomechanical_assessment,
                        slot: existing.slot)
      expect(duplicate).not_to be_valid
    end
  end

  describe "S3 cleanup on destroy" do
    it "deletes the S3 object when the record is destroyed" do
      s3_url = "https://clinic-bucket.s3.us-east-1.amazonaws.com/frontal.jpg"
      image = create(:biomechanical_image, image_url: s3_url)
      s3 = instance_double(S3Presigner, delete: nil)
      allow(S3Presigner).to receive(:new).and_return(s3)

      image.destroy!

      expect(s3).to have_received(:delete).with(public_url: s3_url)
    end

    it "does not call S3 for non-S3 URLs" do
      image = create(:biomechanical_image, image_url: "https://example.com/frontal.jpg")
      expect(S3Presigner).not_to receive(:new)

      image.destroy!
    end
  end
end
