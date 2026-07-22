FactoryBot.define do
  factory :organization do
    sequence(:name) { |n| "Organization #{n}" }
    sequence(:domain) { |n| "org-#{n}" }

    trait :solo do
      solo { true }
    end
  end
end
