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
end
