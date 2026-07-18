require "rails_helper"

RSpec.describe SchedulePlan, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:student) }
    it { is_expected.to belong_to(:trainer) }
    it { is_expected.to have_many(:schedule_plan_slots).dependent(:destroy) }
    it { is_expected.to have_many(:schedule_sessions).dependent(:nullify) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:starts_on) }
    it { is_expected.to validate_presence_of(:ends_on) }

    it "is valid with sensible defaults" do
      expect(build(:schedule_plan)).to be_valid
    end

    it "rejects ends_on before starts_on" do
      plan = build(:schedule_plan, starts_on: Date.new(2026, 7, 20), ends_on: Date.new(2026, 7, 1))
      expect(plan).not_to be_valid
      expect(plan.errors[:ends_on]).to be_present
    end

    it "allows ends_on equal to starts_on" do
      plan = build(:schedule_plan, starts_on: Date.new(2026, 7, 20), ends_on: Date.new(2026, 7, 20))
      expect(plan).to be_valid
    end

    it "rejects a range longer than MAX_RANGE_DAYS" do
      plan = build(:schedule_plan, starts_on: Date.new(2026, 1, 1), ends_on: Date.new(2028, 1, 1))
      expect(plan).not_to be_valid
      expect(plan.errors[:ends_on]).to be_present
    end

    it "accepts a range exactly at MAX_RANGE_DAYS" do
      plan = build(:schedule_plan, starts_on: Date.new(2026, 1, 1),
                                    ends_on: Date.new(2026, 1, 1) + SchedulePlan::MAX_RANGE_DAYS)
      expect(plan).to be_valid
    end

    it "rejects a plan with no slots" do
      plan = build(:schedule_plan)
      plan.schedule_plan_slots = []
      expect(plan).not_to be_valid
      expect(plan.errors[:schedule_plan_slots]).to be_present
    end

    it "rejects notes longer than 500 characters" do
      expect(build(:schedule_plan, notes: "a" * 501)).not_to be_valid
    end
  end
end
