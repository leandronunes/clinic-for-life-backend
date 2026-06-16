require "rails_helper"

RSpec.describe AuditLog, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to belong_to(:auditable).optional }
  end

  describe "validations" do
    subject { build(:audit_log) }

    it { is_expected.to validate_presence_of(:action) }
  end

  it "stores a polymorphic auditable reference" do
    student = create(:student)
    log = create(:audit_log, auditable: student)
    expect(log.auditable).to eq(student)
    expect(log.auditable_type).to eq("Student")
  end
end

RSpec.describe BioimpedanceImport, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:trainer).optional }
  end

  describe "validations" do
    subject { build(:bioimpedance_import) }

    it { is_expected.to validate_presence_of(:filename) }
  end
end
