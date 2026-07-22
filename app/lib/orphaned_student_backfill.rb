# One-off backfill for accounts left orphaned by a self-registration bug:
# a "student"-role User with no linked Student (invisible in the admin's
# listing, unable to reach any student-scoped page). Mirrors
# AuthController#build_student_if_needed's logic, applied retroactively.
# Idempotent — only ever touches users still missing a student_id, so it's
# safe to run again.
class OrphanedStudentBackfill
  Result = Struct.new(:user, :student, :error, keyword_init: true) do
    def success?
      error.nil?
    end
  end

  def self.run!
    User.where(role: "student", student_id: nil).find_each.map { |user| fix(user) }
  end

  def self.fix(user)
    student = nil
    ActiveRecord::Base.transaction do
      student = Student.find_by("lower(email) = ?", user.email) ||
                Student.create!(name: user.name, email: user.email, organization: user.organization)
      user.update!(student: student)
      AuditLog.create!(
        action: "user.backfill_orphaned_student",
        auditable: user,
        justification: "OrphanedStudentBackfill",
        metadata: { student_id: student.id.to_s }
      )
    end
    Result.new(user: user, student: student, error: nil)
  rescue ActiveRecord::RecordInvalid => e
    Result.new(user: user, student: nil, error: e.message)
  end
end
