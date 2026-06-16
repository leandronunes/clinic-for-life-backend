class CreateBioimpedanceImports < ActiveRecord::Migration[8.1]
  def change
    create_table :bioimpedance_imports do |t|
      t.references :trainer, null: true, foreign_key: true
      t.string :filename, null: false
      t.integer :total_rows, null: false, default: 0
      t.integer :imported_count, null: false, default: 0
      t.jsonb :errors_log, null: false, default: []

      t.timestamps
    end
  end
end
