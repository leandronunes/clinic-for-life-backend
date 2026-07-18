class CreateScheduleSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :schedule_sessions do |t|
      t.references :student, null: false, foreign_key: true
      t.references :trainer, null: false, foreign_key: true
      # Nullable — sessão avulsa (sem plano recorrente) é um caso válido.
      t.references :schedule_plan, foreign_key: true
      # Nullable — nenhum fluxo do frontend vincula ainda; existe só para
      # bater com o tipo do contrato (workout_id).
      t.references :workout, foreign_key: true
      t.datetime :starts_at, null: false
      t.integer :duration_minutes, null: false
      t.string :status, null: false, default: "planned"
      t.text :notes

      t.timestamps
    end

    add_index :schedule_sessions, :starts_at
    add_index :schedule_sessions, %i[trainer_id starts_at]
    add_index :schedule_sessions, %i[student_id starts_at]
  end
end
