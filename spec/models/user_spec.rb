require "rails_helper"

RSpec.describe User, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:trainer).optional }
    it { is_expected.to belong_to(:student).optional }
    it { is_expected.to have_many(:audit_logs).dependent(:nullify) }
  end

  describe "validations" do
    subject { build(:user) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to validate_inclusion_of(:role).in_array(User::ROLES) }
    it { is_expected.to have_secure_password }
  end

  describe "email normalization" do
    it "downcases and strips the email before validation" do
      user = create(:user, email: "  MixedCase@Forlife.APP ")
      expect(user.email).to eq("mixedcase@forlife.app")
    end
  end

  describe "password strength" do
    it "is valid with a strong password" do
      expect(build(:user, password: "Str0ng@Pass")).to be_valid
    end

    it "rejects passwords that are too short" do
      user = build(:user, password: "Aa1@b")
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("must be at least 8 characters")
    end

    it "requires an uppercase letter" do
      user = build(:user, password: "weak0@pass")
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("must include an uppercase letter")
    end

    it "requires a lowercase letter" do
      user = build(:user, password: "WEAK0@PASS")
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("must include a lowercase letter")
    end

    it "requires a number" do
      user = build(:user, password: "Weak@Pass")
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("must include a number")
    end

    it "requires a special character" do
      user = build(:user, password: "Weak0Pass")
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("must include a special character")
    end

    it "skips the strength check when password is not being set" do
      user = create(:user)
      user.name = "Updated"
      expect(user.save).to be(true)
    end
  end

  describe "role predicate methods" do
    it "returns true for the matching role" do
      expect(build(:user, :admin)).to be_admin
      expect(build(:user, :personal)).to be_personal
      expect(build(:user, role: "student")).to be_student
    end

    it "returns false for non-matching roles" do
      expect(build(:user, :admin)).not_to be_student
    end
  end
end
