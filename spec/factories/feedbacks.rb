FactoryBot.define do
  factory :feedback do
    association :workout_check_in, :completed
    student { workout_check_in&.student }
    association :author, factory: :user
    kind { "elogio" }
    sequence(:message) { |n| "Mandou muito bem, continue assim! (#{n})" }
  end
end
