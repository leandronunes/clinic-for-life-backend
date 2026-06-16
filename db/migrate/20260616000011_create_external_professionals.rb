class CreateExternalProfessionals < ActiveRecord::Migration[8.1]
  def change
    create_table :external_professionals do |t|
      t.references :anamnesis, null: false, foreign_key: true
      t.string :name, null: false
      t.string :specialty
      t.string :objective

      t.timestamps
    end
  end
end
