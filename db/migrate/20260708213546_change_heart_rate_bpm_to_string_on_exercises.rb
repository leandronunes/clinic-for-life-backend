class ChangeHeartRateBpmToStringOnExercises < ActiveRecord::Migration[8.1]
  def up
    change_column :exercises, :heart_rate_bpm, :string
  end

  def down
    change_column :exercises, :heart_rate_bpm, :integer
  end
end
