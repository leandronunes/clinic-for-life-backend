FactoryBot.define do
  factory :audit_log do
    association :user
    action { "test.action" }
    ip_address { "127.0.0.1" }
    metadata { {} }
  end
end
