FactoryBot.define do
  factory :chat_message do
    association :student
    sender_role { "personal" }
    association :sender, factory: [ :user, :personal ]
    sequence(:body) { |n| "Mensagem #{n}" }
    read_at { nil }

    trait :from_aluno do
      sender_role { "aluno" }
      association :sender, factory: [ :user, :student_account ]
    end

    trait :from_personal do
      sender_role { "personal" }
      association :sender, factory: [ :user, :personal ]
    end

    trait :read do
      read_at { Time.current }
    end
  end
end
