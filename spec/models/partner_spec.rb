require "rails_helper"

RSpec.describe Partner, type: :model do
  describe "validations" do
    subject { build(:partner) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:category) }

    it "accepts any free-text category" do
      expect(build(:partner, category: "Odontologia")).to be_valid
    end
  end
end
