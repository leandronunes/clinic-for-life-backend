class AddAttendanceCycleToStudents < ActiveRecord::Migration[8.1]
  def change
    add_column :students, :contracted_workouts_per_cycle, :integer
    add_column :students, :cycle_started_at, :datetime
  end
end
