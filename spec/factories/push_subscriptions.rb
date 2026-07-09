FactoryBot.define do
  factory :push_subscription do
    association :user, :student_account
    sequence(:endpoint) { |n| "https://fcm.googleapis.com/fcm/send/mock-#{n}" }
    p256dh_key { "BN4GvZtEZiZuqFhSKgXqjNaJZ0aEDBJXjJgqL8yUxJgqL8yUxJgqL8yUxJgqL8y" }
    auth_key { "k8JV6sd3rDkfg7NlV_2h6Q" }
    user_agent { "Mozilla/5.0 (Test)" }
  end
end
