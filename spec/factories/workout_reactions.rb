FactoryBot.define do
  factory :workout_reaction do
    association :workout_check_in, :completed
    association :author, factory: :user
    emoji { "💪" }
  end
end
