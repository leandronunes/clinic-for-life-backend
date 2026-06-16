class CreateWorkouts < ActiveRecord::Migration[8.1]
  def change
    create_table :workouts do |t|
      t.references :student, null: false, foreign_key: true
      t.integer :position, null: false, default: 1
      t.string :title, null: false
      t.string :focus
      t.string :status, null: false, default: "active"
      t.string :trainer_name
      t.datetime :archived_at

      t.timestamps
    end

    add_index :workouts, [ :student_id, :status ]
  end
end
