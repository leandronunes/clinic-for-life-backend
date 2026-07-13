class AddViewedAtToWorkoutCheckIns < ActiveRecord::Migration[8.1]
  def change
    add_column :workout_check_ins, :viewed_at, :datetime
  end
end
