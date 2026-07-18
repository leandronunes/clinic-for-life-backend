FactoryBot.define do
  factory :schedule_plan do
    association :student
    trainer { student.trainer }
    starts_on { Date.current }
    ends_on { 1.month.from_now.to_date }

    after(:build) do |plan|
      plan.schedule_plan_slots << FactoryBot.build(:schedule_plan_slot, schedule_plan: plan) if plan.schedule_plan_slots.empty?
    end
  end
end
