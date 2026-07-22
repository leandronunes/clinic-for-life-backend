FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "User #{n}" }
    sequence(:email) { |n| "user#{n}@forlife.app" }
    password { "Str0ng@Pass" }
    role { "student" }
    terms_accepted_at { Time.current }
    association :organization

    trait :admin do
      role { "admin" }
      trainer { nil }
      student { nil }
    end

    trait :personal do
      role { "personal" }
      association :trainer
      organization { trainer.organization }
    end

    trait :student_account do
      role { "student" }
      association :student
      organization { student.organization }
    end
  end
end
