class CreateAttendanceCycles < ActiveRecord::Migration[8.1]
  def change
    create_table :attendance_cycles do |t|
      t.references :student, null: false, foreign_key: true
      t.integer :contracted_workouts_per_cycle, null: false
      t.datetime :started_at, null: false
      t.datetime :ended_at, null: false

      t.timestamps
    end
  end
end
