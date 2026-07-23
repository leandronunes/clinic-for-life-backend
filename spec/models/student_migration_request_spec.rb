require "rails_helper"

RSpec.describe StudentMigrationRequest, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:student) }
    it { is_expected.to belong_to(:requested_by).class_name("User") }
    it { is_expected.to belong_to(:source_organization).class_name("Organization") }
    it { is_expected.to belong_to(:target_organization).class_name("Organization") }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_inclusion_of(:status).in_array(StudentMigrationRequest::STATUSES) }

    it "requires the source and target organizations to differ" do
      org = create(:organization)
      student = create(:student, organization: org, trainer: create(:trainer, organization: org))
      admin = create(:user, :admin, organization: org)

      request = build(:student_migration_request,
                      student: student, requested_by: admin,
                      source_organization: org, target_organization: org)

      expect(request).not_to be_valid
      expect(request.errors[:target_organization_id]).to be_present
    end
  end

  describe "one pending request per student" do
    it "rejects a second pending request for the same student at the database level" do
      student = create(:student)
      create(:student_migration_request, student: student)

      expect do
        create(:student_migration_request, student: student)
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "allows a new request once the previous one is no longer pending" do
      student = create(:student)
      create(:student_migration_request, student: student, status: "rejected")

      expect(build(:student_migration_request, student: student)).to be_valid
    end
  end

  describe ".pending" do
    it "only includes pending requests" do
      pending_request = create(:student_migration_request, status: "pending")
      create(:student_migration_request, status: "accepted")

      expect(StudentMigrationRequest.pending).to contain_exactly(pending_request)
    end
  end

  describe "status predicates" do
    it "exposes pending?/accepted?/rejected?" do
      request = build(:student_migration_request, status: "accepted")
      expect(request.accepted?).to be(true)
      expect(request.pending?).to be(false)
      expect(request.rejected?).to be(false)
    end
  end
end
