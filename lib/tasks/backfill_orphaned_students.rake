# See app/lib/orphaned_student_backfill.rb for the actual logic — this task
# is just the CLI entry point (`bin/rails backfill:orphaned_students`).
namespace :backfill do
  desc "Links or creates a Student profile for every student-role user left without one"
  task orphaned_students: :environment do
    results = OrphanedStudentBackfill.run!
    puts "Found #{results.size} orphaned student-role user(s)."

    results.each do |result|
      if result.success?
        puts "  ✓ #{result.user.email} → student ##{result.student.id}"
      else
        puts "  ✗ #{result.user.email}: #{result.error}"
      end
    end

    fixed = results.count(&:success?)
    failed = results.size - fixed
    puts "Done. Fixed #{fixed}, failed #{failed}."
  end
end
