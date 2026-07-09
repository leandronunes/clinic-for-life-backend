require "rails_helper"

RSpec.describe PushSubscription, type: :model do
  describe "validations" do
    subject { build(:push_subscription) }

    it { is_expected.to belong_to(:user) }
    it { is_expected.to validate_presence_of(:endpoint) }
    it { is_expected.to validate_uniqueness_of(:endpoint) }
    it { is_expected.to validate_presence_of(:p256dh_key) }
    it { is_expected.to validate_presence_of(:auth_key) }
  end
end
