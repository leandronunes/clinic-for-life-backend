require "rails_helper"

RSpec.describe SchedulePlanSlot, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:schedule_plan) }
  end

  describe "validations" do
    subject { build(:schedule_plan_slot) }

    it { is_expected.to validate_inclusion_of(:weekday).in_array(SchedulePlanSlot::WEEKDAYS.to_a) }
    it { is_expected.to validate_numericality_of(:duration_minutes).only_integer }

    it "is valid with sensible defaults" do
      expect(build(:schedule_plan_slot)).to be_valid
    end

    it "accepts weekday 0 (domingo)" do
      expect(build(:schedule_plan_slot, weekday: 0)).to be_valid
    end

    it "rejects weekday outside 0..6" do
      expect(build(:schedule_plan_slot, weekday: 7)).not_to be_valid
      expect(build(:schedule_plan_slot, weekday: -1)).not_to be_valid
    end

    it "rejects a malformed time" do
      expect(build(:schedule_plan_slot, time: "7:00")).not_to be_valid
      expect(build(:schedule_plan_slot, time: "25:00")).not_to be_valid
      expect(build(:schedule_plan_slot, time: "not-a-time")).not_to be_valid
    end

    it "accepts a well-formed HH:mm time" do
      expect(build(:schedule_plan_slot, time: "23:59")).to be_valid
    end

    it "rejects duration_minutes outside 15..240" do
      expect(build(:schedule_plan_slot, duration_minutes: 14)).not_to be_valid
      expect(build(:schedule_plan_slot, duration_minutes: 241)).not_to be_valid
    end

    it "accepts duration_minutes at the boundaries" do
      expect(build(:schedule_plan_slot, duration_minutes: 15)).to be_valid
      expect(build(:schedule_plan_slot, duration_minutes: 240)).to be_valid
    end

    it "rejects a second slot for the same weekday on the same plan" do
      plan = create(:schedule_plan)
      existing_weekday = plan.schedule_plan_slots.first.weekday
      duplicate = build(:schedule_plan_slot, schedule_plan: plan, weekday: existing_weekday)
      expect(duplicate).not_to be_valid
    end

    it "allows the same weekday across different plans" do
      create(:schedule_plan) # persiste com um slot de weekday 1 (default da factory)
      another_plan = build(:schedule_plan) # também ganha um slot de weekday 1
      expect(another_plan.schedule_plan_slots.first.weekday).to eq(1)
      expect(another_plan).to be_valid
    end
  end
end
