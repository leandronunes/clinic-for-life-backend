class RemoveTrainerNameFromWorkouts < ActiveRecord::Migration[8.1]
  def change
    remove_column :workouts, :trainer_name, :string
  end
end
