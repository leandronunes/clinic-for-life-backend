class LinkEvolutionPhotosToMeasurements < ActiveRecord::Migration[8.1]
  def change
    # Remove metric columns that duplicate bioimpedance_measurements data
    remove_column :evolution_photos, :weight_kg, :decimal
    remove_column :evolution_photos, :fat_percentage, :decimal
    remove_column :evolution_photos, :muscle_mass_kg, :decimal

    # Link each photo to the measurement session it was taken during
    add_reference :evolution_photos, :bioimpedance_measurement,
                  null: true, foreign_key: true, index: { unique: true }
  end
end
