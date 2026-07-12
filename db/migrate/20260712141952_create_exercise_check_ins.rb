class CreateExerciseCheckIns < ActiveRecord::Migration[8.1]
  def change
    create_table :exercise_check_ins do |t|
      t.references :workout_check_in, null: false, foreign_key: true
      t.references :exercise, null: false, foreign_key: true
      t.datetime :completed_at, null: false
      t.timestamps
    end
    add_index :exercise_check_ins, [ :workout_check_in_id, :exercise_id ], unique: true,
              name: "index_exercise_check_ins_on_check_in_and_exercise"
  end
end
