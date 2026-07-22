FactoryBot.define do
  factory :trainer do
    sequence(:name) { |n| "Trainer #{n}" }
    sequence(:cpf) { |n| format("%011d", n) }
    sequence(:cref) { |n| "#{format('%06d', n)}-G/SP" }
    sequence(:email) { |n| "trainer#{n}@forlife.app" }
    phone { "(11) 98888-0000" }
    status { "active" }
    association :organization
    approved_at { Time.current }
  end
end
