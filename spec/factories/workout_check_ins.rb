FactoryBot.define do
  factory :workout_check_in do
    association :workout
    student { workout.student }
    status { "in_progress" }

    trait :completed do
      status { "completed" }
      completed_at { Time.current }
    end

    trait :performed_by_personal do
      performed_by { "personal" }
    end

    trait :with_pse do
      pse { 7 }
    end
  end
end
