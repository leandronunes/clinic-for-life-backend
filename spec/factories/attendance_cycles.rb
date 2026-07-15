FactoryBot.define do
  factory :attendance_cycle do
    association :student
    contracted_workouts_per_cycle { 8 }
    started_at { 2.months.ago }
    ended_at { 1.month.ago }
  end
end
