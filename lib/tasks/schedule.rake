# See app/services/schedule_missed_marker_service.rb for the actual logic —
# this task is just the CLI entry point (`bin/rails schedule:mark_missed`),
# also callable manually/for debugging. The recurring trigger in production
# is .github/workflows/schedule_mark_missed.yml, which calls the internal
# HTTP endpoint (Api::V1::CronController) instead, since there's no
# persistent worker process to run a rake task on a schedule.
namespace :schedule do
  desc "Marks 'planned' schedule sessions whose end time has passed as 'missed'"
  task mark_missed: :environment do
    puts "Marked #{ScheduleMissedMarkerService.call} session(s) as missed"
  end
end
