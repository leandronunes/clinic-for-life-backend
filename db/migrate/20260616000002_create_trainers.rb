class CreateTrainers < ActiveRecord::Migration[8.1]
  def change
    create_table :trainers do |t|
      t.string :name, null: false
      t.string :cpf, null: false
      t.string :cref, null: false
      t.string :email, null: false
      t.string :phone
      t.string :status, null: false, default: "active"
      t.string :avatar_url

      t.timestamps
    end

    add_index :trainers, :email, unique: true
    add_index :trainers, :cpf, unique: true
    add_index :trainers, :cref, unique: true
    add_index :trainers, :status
  end
end
