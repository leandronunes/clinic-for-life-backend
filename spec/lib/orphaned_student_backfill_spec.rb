require "rails_helper"

RSpec.describe OrphanedStudentBackfill do
  describe ".run!" do
    it "builds a new student profile for an orphaned student-role user, matching name and email" do
      user = create(:user, name: "Ana Carolina", email: "ana@email.com")

      expect do
        results = described_class.run!
        expect(results.size).to eq(1)
        expect(results.first).to be_success
      end.to change(Student, :count).by(1)

      user.reload
      expect(user.student).to be_present
      expect(user.student.name).to eq("Ana Carolina")
      expect(user.student.email).to eq("ana@email.com")
    end

    it "links to an existing student record with the same e-mail instead of creating a duplicate" do
      student = create(:student, email: "ana@email.com")
      user = create(:user, email: "ana@email.com")

      expect { described_class.run! }.not_to change(Student, :count)

      expect(user.reload.student_id).to eq(student.id)
    end

    it "does not touch a student-role user that already has a student profile" do
      user = create(:user, :student_account)
      original_student_id = user.student_id

      expect { described_class.run! }.not_to change(Student, :count)

      expect(user.reload.student_id).to eq(original_student_id)
    end

    it "does not touch admin or personal accounts" do
      create(:user, :admin)
      create(:user, :personal)

      expect { described_class.run! }.not_to change(Student, :count)
      expect(described_class.run!).to be_empty
    end

    it "fixes multiple orphaned users independently, even with the same name" do
      first = create(:user, name: "Ana Carolina", email: "ana1@email.com")
      second = create(:user, name: "Ana Carolina", email: "ana2@email.com")

      results = described_class.run!

      expect(results.size).to eq(2)
      expect(results).to all(be_success)
      expect(first.reload.student_id).not_to eq(second.reload.student_id)
    end

    it "records an audit log entry for each fixed user" do
      user = create(:user, email: "ana@email.com")

      expect { described_class.run! }.to change(AuditLog, :count).by(1)
      log = AuditLog.last
      expect(log.action).to eq("user.backfill_orphaned_student")
      expect(log.auditable).to eq(user)
    end

    it "is idempotent — running it twice only fixes each user once" do
      create(:user, email: "ana@email.com")

      described_class.run!
      second_run = described_class.run!

      expect(second_run).to be_empty
    end
  end

  describe ".fix" do
    it "returns a failed result instead of raising when the user cannot be saved" do
      user = create(:user, email: "ana@email.com")
      allow(user).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(user))

      result = described_class.fix(user)

      expect(result).not_to be_success
      expect(result.error).to be_present
    end
  end
end
