FactoryBot.define do
  factory :feedback do
    association :student
    association :author, factory: :user
    kind { "elogio" }
    sequence(:message) { |n| "Mandou muito bem, continue assim! (#{n})" }
  end
end
