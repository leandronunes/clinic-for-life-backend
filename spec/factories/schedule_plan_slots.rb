FactoryBot.define do
  factory :schedule_plan_slot do
    association :schedule_plan
    weekday { 1 }
    time { "07:00" }
    duration_minutes { 60 }
  end
end
