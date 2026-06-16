require "rails_helper"

RSpec.describe Exercise, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:workout) }
  end

  describe "validations" do
    subject { build(:exercise) }

    it { is_expected.to validate_presence_of(:name) }

    it "requires a positive number of sets" do
      expect(build(:exercise, sets: 0)).not_to be_valid
    end

    it "rejects negative rest seconds" do
      expect(build(:exercise, rest_seconds: -5)).not_to be_valid
    end

    it "allows zero rest seconds" do
      expect(build(:exercise, rest_seconds: 0)).to be_valid
    end
  end
end
