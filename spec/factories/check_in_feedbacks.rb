FactoryBot.define do
  factory :check_in_feedback do
    association :workout_check_in, :completed
    association :author, factory: :user
    sequence(:message) { |n| "Mandou muito bem, continue assim! (#{n})" }

    trait :with_emoji do
      emoji { "💪" }
      message { nil }
    end

    trait :with_message_and_emoji do
      emoji { "🔥" }
    end
  end
end
