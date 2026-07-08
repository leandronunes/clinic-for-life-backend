class AddKindAndCardioFieldsToExercises < ActiveRecord::Migration[8.1]
  def change
    add_column :exercises, :kind, :string, null: false, default: "strength"
    add_column :exercises, :duration_seconds, :integer
    add_column :exercises, :distance_value, :decimal, precision: 6, scale: 2
    add_column :exercises, :distance_unit, :string
    add_column :exercises, :hr_zone, :integer
    add_column :exercises, :heart_rate_bpm, :integer
  end
end
