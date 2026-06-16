class CreateExercises < ActiveRecord::Migration[8.1]
  def change
    create_table :exercises do |t|
      t.references :workout, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :sets, null: false, default: 1
      t.string :reps
      t.decimal :load_kg, precision: 6, scale: 2
      t.integer :rest_seconds, null: false, default: 60
      t.string :muscle_group
      t.string :video_url
      t.text :notes
      t.integer :position, null: false, default: 1

      t.timestamps
    end
  end
end
