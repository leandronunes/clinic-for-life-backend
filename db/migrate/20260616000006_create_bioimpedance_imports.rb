class CreateBioimpedanceImports < ActiveRecord::Migration[8.1]
  def change
    json_type = connection.adapter_name.start_with?("PostgreSQL") ? :jsonb : :json

    create_table :bioimpedance_imports do |t|
      t.references :trainer, null: true, foreign_key: true
      t.string :filename, null: false
      t.integer :total_rows, null: false, default: 0
      t.integer :imported_count, null: false, default: 0
      t.column :errors_log, json_type, null: false, default: []

      t.timestamps
    end
  end
end
