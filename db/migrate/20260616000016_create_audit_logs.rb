class CreateAuditLogs < ActiveRecord::Migration[8.1]
  def change
    json_type = connection.adapter_name.start_with?("PostgreSQL") ? :jsonb : :json

    create_table :audit_logs do |t|
      t.references :user, null: true, foreign_key: true
      t.string :action, null: false
      t.string :auditable_type
      t.bigint :auditable_id
      t.string :ip_address
      t.string :justification
      t.column :metadata, json_type, null: false, default: {}

      t.timestamps
    end

    add_index :audit_logs, [ :auditable_type, :auditable_id ]
  end
end
