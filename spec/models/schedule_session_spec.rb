require "rails_helper"

RSpec.describe ScheduleSession, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:student) }
    it { is_expected.to belong_to(:trainer) }
    it { is_expected.to belong_to(:schedule_plan).optional }
    it { is_expected.to belong_to(:workout).optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:starts_at) }
    it { is_expected.to validate_inclusion_of(:status).in_array(ScheduleSession::STATUSES) }

    it "is valid with sensible defaults" do
      expect(build(:schedule_session)).to be_valid
    end

    it "defaults status to planned" do
      expect(ScheduleSession.new.status).to eq("planned")
    end

    it "rejects duration_minutes outside 15..240" do
      expect(build(:schedule_session, duration_minutes: 14)).not_to be_valid
      expect(build(:schedule_session, duration_minutes: 241)).not_to be_valid
    end

    it "accepts duration_minutes at the boundaries" do
      expect(build(:schedule_session, duration_minutes: 15)).to be_valid
      expect(build(:schedule_session, duration_minutes: 240)).to be_valid
    end

    it "is valid without a schedule_plan or workout (avulsa)" do
      session = build(:schedule_session, schedule_plan: nil, workout: nil)
      expect(session).to be_valid
    end
  end
end
