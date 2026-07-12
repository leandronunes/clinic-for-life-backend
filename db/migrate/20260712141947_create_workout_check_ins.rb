class CreateWorkoutCheckIns < ActiveRecord::Migration[8.1]
  def up
    create_table :workout_check_ins do |t|
      t.references :workout, null: false, foreign_key: true
      t.references :student, null: false, foreign_key: true
      t.string :status, null: false, default: "in_progress"
      t.datetime :completed_at
      t.timestamps
    end
    add_index :workout_check_ins, [ :student_id, :created_at ]

    # A workout can have at most one in-progress check-in at a time — enforced
    # at the DB level (not just app validation) since "Iniciar treino" being
    # tapped twice in a race must not create two concurrent sessions.
    execute <<~SQL
      CREATE UNIQUE INDEX index_workout_check_ins_on_workout_in_progress
      ON workout_check_ins (workout_id) WHERE (status = 'in_progress')
    SQL
  end

  def down
    remove_index :workout_check_ins, name: "index_workout_check_ins_on_workout_in_progress"
    drop_table :workout_check_ins
  end
end
