class CreateBioimpedanceMeasurements < ActiveRecord::Migration[8.1]
  def change
    create_table :bioimpedance_measurements do |t|
      t.references :student, null: false, foreign_key: true
      t.decimal :weight_kg, precision: 6, scale: 2, null: false
      t.decimal :muscle_mass_kg, precision: 6, scale: 2
      t.decimal :fat_percentage, precision: 5, scale: 2
      t.decimal :visceral_fat, precision: 5, scale: 2
      t.decimal :bmi, precision: 5, scale: 2
      t.date :measured_on, null: false
      t.string :source, null: false, default: "InBody"

      t.timestamps
    end

    add_index :bioimpedance_measurements, [ :student_id, :measured_on ], unique: true
  end
end
