class CreateEvolutionPhotos < ActiveRecord::Migration[8.1]
  def change
    create_table :evolution_photos do |t|
      t.references :student, null: false, foreign_key: true
      t.date :taken_on, null: false
      t.string :image_url, null: false
      t.decimal :weight_kg, precision: 6, scale: 2
      t.decimal :fat_percentage, precision: 5, scale: 2
      t.decimal :muscle_mass_kg, precision: 6, scale: 2

      t.timestamps
    end
  end
end
