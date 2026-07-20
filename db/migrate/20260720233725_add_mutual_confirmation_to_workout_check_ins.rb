class AddMutualConfirmationToWorkoutCheckIns < ActiveRecord::Migration[8.1]
  def up
    add_column :workout_check_ins, :student_confirmed_at, :datetime
    add_column :workout_check_ins, :personal_confirmed_at, :datetime

    # Preserva a contagem de cota exatamente como está hoje: linhas
    # "personal" já contavam -> ambas confirmadas; linhas "aluno" nunca
    # contavam (se tivessem sido claimed, já estariam como "personal") ->
    # só o lado do aluno. O valor exato do timestamp é inerte para a
    # contagem (que passa a ser por presença, não por valor) — created_at
    # é usado por estar sempre presente (completed_at é nulo em in_progress).
    execute <<~SQL
      UPDATE workout_check_ins
      SET student_confirmed_at = created_at,
          personal_confirmed_at = created_at
      WHERE performed_by = 'personal'
    SQL
    execute <<~SQL
      UPDATE workout_check_ins
      SET student_confirmed_at = created_at
      WHERE performed_by = 'aluno'
    SQL

    remove_column :workout_check_ins, :performed_by
  end

  def down
    add_column :workout_check_ins, :performed_by, :string, null: false, default: "aluno"
    execute <<~SQL
      UPDATE workout_check_ins
      SET performed_by = 'personal'
      WHERE personal_confirmed_at IS NOT NULL
    SQL
    remove_column :workout_check_ins, :student_confirmed_at
    remove_column :workout_check_ins, :personal_confirmed_at
  end
end
