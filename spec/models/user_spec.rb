require "rails_helper"

RSpec.describe User, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:trainer).optional }
    it { is_expected.to belong_to(:student).optional }
    it { is_expected.to belong_to(:organization) }
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

  describe "#generate_password_reset_token!" do
    it "returns a raw token and persists only its digest" do
      user = create(:user)
      raw_token = user.generate_password_reset_token!

      expect(raw_token).to be_present
      expect(user.reset_password_token_digest).to eq(Digest::SHA256.hexdigest(raw_token))
      expect(user.reset_password_token_digest).not_to eq(raw_token)
    end

    it "sets reset_password_sent_at to now" do
      user = create(:user)
      user.generate_password_reset_token!
      expect(user.reset_password_sent_at).to be_within(2.seconds).of(Time.current)
    end

    it "returns a different token each time it is called" do
      user = create(:user)
      first = user.generate_password_reset_token!
      second = user.generate_password_reset_token!
      expect(first).not_to eq(second)
    end
  end

  describe ".find_by_valid_reset_token" do
    it "finds the user by the raw token" do
      user = create(:user)
      raw_token = user.generate_password_reset_token!
      expect(User.find_by_valid_reset_token(raw_token)).to eq(user)
    end

    it "returns nil for an unknown token" do
      expect(User.find_by_valid_reset_token("does-not-exist")).to be_nil
    end

    it "returns nil for a blank token" do
      expect(User.find_by_valid_reset_token(nil)).to be_nil
      expect(User.find_by_valid_reset_token("")).to be_nil
    end

    it "returns nil once the token has expired" do
      user = create(:user)
      raw_token = user.generate_password_reset_token!
      user.update_column(:reset_password_sent_at, User::RESET_TOKEN_EXPIRY.ago - 1.second)

      expect(User.find_by_valid_reset_token(raw_token)).to be_nil
    end
  end

  describe "#clear_password_reset_token!" do
    it "clears both the digest and the timestamp" do
      user = create(:user)
      user.generate_password_reset_token!

      user.clear_password_reset_token!

      expect(user.reset_password_token_digest).to be_nil
      expect(user.reset_password_sent_at).to be_nil
    end
  end
end
