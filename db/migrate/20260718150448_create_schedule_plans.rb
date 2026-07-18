class CreateSchedulePlans < ActiveRecord::Migration[8.1]
  def change
    create_table :schedule_plans do |t|
      t.references :student, null: false, foreign_key: true
      t.references :trainer, null: false, foreign_key: true
      t.date :starts_on, null: false
      t.date :ends_on, null: false
      t.text :notes

      t.timestamps
    end
  end
end
