require "rails_helper"

RSpec.describe BioimpedanceMeasurement, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:student) }
  end

  describe "validations" do
    subject { build(:bioimpedance_measurement) }

    it { is_expected.to validate_presence_of(:weight_kg) }
    it { is_expected.to validate_presence_of(:measured_on) }

    it "rejects a non-positive weight" do
      expect(build(:bioimpedance_measurement, weight_kg: 0)).not_to be_valid
    end

    it "rejects a fat percentage above 75" do
      expect(build(:bioimpedance_measurement, fat_percentage: 80)).not_to be_valid
    end

    it "rejects a negative fat percentage" do
      expect(build(:bioimpedance_measurement, fat_percentage: -1)).not_to be_valid
    end

    it "allows a nil fat percentage" do
      expect(build(:bioimpedance_measurement, fat_percentage: nil)).to be_valid
    end

    it "rejects a measurement dated in the future" do
      measurement = build(:bioimpedance_measurement, measured_on: Date.current + 1)
      expect(measurement).not_to be_valid
      expect(measurement.errors[:measured_on]).to include("cannot be in the future")
    end

    it "enforces uniqueness per student and date" do
      existing = create(:bioimpedance_measurement)
      duplicate = build(:bioimpedance_measurement,
                        student: existing.student, measured_on: existing.measured_on)
      expect(duplicate).not_to be_valid
    end
  end

  describe "BMI" do
    it "stores a provided BMI value" do
      measurement = create(:bioimpedance_measurement, bmi: 30)
      expect(measurement.bmi).to eq(30)
    end

    it "allows a nil BMI" do
      measurement = create(:bioimpedance_measurement, bmi: nil)
      expect(measurement.bmi).to be_nil
    end
  end
end
