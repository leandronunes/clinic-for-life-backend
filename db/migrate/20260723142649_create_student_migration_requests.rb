class CreateStudentMigrationRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :student_migration_requests do |t|
      t.references :student, null: false, foreign_key: true
      t.references :requested_by, null: false, foreign_key: { to_table: :users }
      t.references :source_organization, null: false, foreign_key: { to_table: :organizations }
      t.references :target_organization, null: false, foreign_key: { to_table: :organizations }
      t.string :status, null: false, default: "pending"
      t.datetime :responded_at

      t.timestamps
    end

    # Enforces "at most one pending request per student" in the database, not
    # just in application code — a second admin racing to invite the same
    # student concurrently must not be able to create a second pending row.
    add_index :student_migration_requests, :student_id, unique: true,
              where: "status = 'pending'", name: "index_one_pending_migration_per_student"
  end
end
