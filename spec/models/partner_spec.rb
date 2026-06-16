require "rails_helper"

RSpec.describe Partner, type: :model do
  describe "validations" do
    subject { build(:partner) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:category) }
    it { is_expected.to validate_inclusion_of(:category).in_array(Partner::CATEGORIES) }

    it "rejects an unknown category" do
      expect(build(:partner, category: "Unknown")).not_to be_valid
    end
  end
end
