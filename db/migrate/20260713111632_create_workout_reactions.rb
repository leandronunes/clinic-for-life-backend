class CreateWorkoutReactions < ActiveRecord::Migration[8.1]
  def change
    create_table :workout_reactions do |t|
      t.references :workout_check_in, null: false, foreign_key: true
      t.references :author, foreign_key: { to_table: :users }
      t.string :emoji, null: false
      t.timestamps
    end
    add_index :workout_reactions, %i[workout_check_in_id author_id], unique: true,
              name: "index_workout_reactions_on_check_in_and_author"
  end
end
