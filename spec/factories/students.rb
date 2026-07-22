FactoryBot.define do
  factory :student do
    sequence(:name) { |n| "Student #{n}" }
    sequence(:email) { |n| "student#{n}@email.com" }
    birth_date { "1995-01-01" }
    sex { "female" }
    phone { "(11) 97777-0000" }
    status { "active" }
    association :trainer
    organization { trainer&.organization || association(:organization) }
  end
end
