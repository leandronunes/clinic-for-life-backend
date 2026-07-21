class AddWorkoutCheckInToScheduleSessions < ActiveRecord::Migration[8.1]
  def change
    add_reference :schedule_sessions, :workout_check_in, foreign_key: true, index: { unique: true }
  end
end
