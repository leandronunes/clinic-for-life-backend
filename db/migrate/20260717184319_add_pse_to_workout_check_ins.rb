class AddPseToWorkoutCheckIns < ActiveRecord::Migration[8.1]
  def change
    # Percepção Subjetiva de Esforço (escala de Borg CR-10 simplificada,
    # 1-10). Nullable — nil significa "ainda não capturada" (check-in em
    # andamento, ou o aluno pulou a captura ao concluir).
    add_column :workout_check_ins, :pse, :integer
  end
end
