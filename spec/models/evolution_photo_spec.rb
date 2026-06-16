require "rails_helper"

RSpec.describe EvolutionPhoto, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:student) }
  end

  describe "validations" do
    subject { build(:evolution_photo) }

    it { is_expected.to validate_presence_of(:taken_on) }
    it { is_expected.to validate_presence_of(:image_url) }
  end
end
