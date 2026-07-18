class CreateSchedulePlanSlots < ActiveRecord::Migration[8.1]
  def change
    create_table :schedule_plan_slots do |t|
      t.references :schedule_plan, null: false, foreign_key: true
      t.integer :weekday, null: false
      # "HH:mm" string, não t.time — evita a ambiguidade da coluna time do
      # Rails (grava com data bogus, depende de Time.zone). A conversão para
      # o instante certo é sempre explícita via ScheduleExpansionService.
      t.string :time, null: false
      t.integer :duration_minutes, null: false

      t.timestamps
    end

    add_index :schedule_plan_slots, %i[schedule_plan_id weekday], unique: true
  end
end
