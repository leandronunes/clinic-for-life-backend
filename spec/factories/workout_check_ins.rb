FactoryBot.define do
  factory :workout_check_in do
    association :workout
    student { workout.student }
    status { "in_progress" }

    trait :completed do
      status { "completed" }
      completed_at { Time.current }
    end

    trait :mutually_confirmed do
      student_confirmed_at { Time.current }
      personal_confirmed_at { Time.current }
    end

    trait :personal_performed do
      student_confirmed_at { nil }
      personal_confirmed_at { Time.current }
    end

    trait :student_performed do
      student_confirmed_at { Time.current }
      personal_confirmed_at { nil }
    end

    trait :with_pse do
      pse { 7 }
    end
  end
end
