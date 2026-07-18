FactoryBot.define do
  factory :schedule_session do
    association :student
    trainer { student.trainer }
    starts_at { 1.day.from_now }
    duration_minutes { 60 }
    status { "planned" }

    trait :planned_in_the_past do
      status { "planned" }
      starts_at { 2.hours.ago }
      duration_minutes { 30 }
    end
  end
end
