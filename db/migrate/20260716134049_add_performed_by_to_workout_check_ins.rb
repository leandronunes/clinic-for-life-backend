class AddPerformedByToWorkoutCheckIns < ActiveRecord::Migration[8.1]
  def change
    # Default "aluno" — every check-in created before this column existed was
    # self-service by definition (there was no other way to create one).
    add_column :workout_check_ins, :performed_by, :string, null: false, default: "aluno"
  end
end
