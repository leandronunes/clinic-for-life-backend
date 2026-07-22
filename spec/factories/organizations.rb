FactoryBot.define do
  factory :organization do
    sequence(:name) { |n| "Organization #{n}" }
    sequence(:domain) { |n| "org-#{n}" }
  end
end
