class CreateAnamneses < ActiveRecord::Migration[8.1]
  def change
    create_table :anamneses do |t|
      t.references :student, null: false, foreign_key: true, index: { unique: true }

      # Objectives
      t.text :objectives

      # Clinical picture
      t.text :medicines
      t.text :supplements
      t.string :systolic_pressure
      t.string :diastolic_pressure
      t.string :variable_glycemia
      t.text :notes

      # Orthopedic assessment
      t.string :height
      t.string :weight
      t.text :fracture
      t.text :dislocations
      t.text :pain
      t.text :orthopedic_notes

      # Lifestyle habits
      t.text :meals
      t.string :hydration
      t.string :sleep
      t.string :stool
      t.string :urine

      t.timestamps
    end
  end
end
