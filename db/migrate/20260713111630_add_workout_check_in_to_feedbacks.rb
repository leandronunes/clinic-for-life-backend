class AddWorkoutCheckInToFeedbacks < ActiveRecord::Migration[8.1]
  def up
    # Pre-existing rows predate the workout_check_in association (feedback
    # used to be a general note, not tied to a specific workout) and can't
    # be backfilled — there's no check-in to attribute them to. No real user
    # data depends on this table yet.
    execute "DELETE FROM feedbacks"
    add_reference :feedbacks, :workout_check_in, null: false, foreign_key: true
  end

  def down
    remove_reference :feedbacks, :workout_check_in, foreign_key: true
  end
end
