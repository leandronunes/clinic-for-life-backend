FactoryBot.define do
  factory :student_migration_request do
    association :student
    source_organization { student.organization }
    target_organization { association(:organization) }
    requested_by { association(:user, :admin, organization: target_organization) }
    status { "pending" }
  end
end
