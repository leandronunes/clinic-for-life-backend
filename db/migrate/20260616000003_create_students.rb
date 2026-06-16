class CreateStudents < ActiveRecord::Migration[8.1]
  def change
    create_table :students do |t|
      t.string :name, null: false
      t.date :birth_date
      t.string :sex, null: false, default: "other"
      t.integer :height_cm
      t.string :email, null: false
      t.string :phone
      t.references :trainer, null: true, foreign_key: true
      t.string :status, null: false, default: "active"
      t.string :health_plan
      t.string :emergency_contact

      t.timestamps
    end

    add_index :students, :email, unique: true
    add_index :students, :status
  end
end
