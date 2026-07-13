class CreateCheckInFeedbacks < ActiveRecord::Migration[8.1]
  def up
    create_table :check_in_feedbacks do |t|
      t.references :workout_check_in, null: false, foreign_key: true
      t.references :author, null: true, foreign_key: { to_table: :users }
      t.string :emoji
      t.text :message
      t.timestamps
    end

    # Migrate text feedbacks
    execute <<~SQL
      INSERT INTO check_in_feedbacks (workout_check_in_id, author_id, message, created_at, updated_at)
      SELECT workout_check_in_id, author_id, message, created_at, updated_at
      FROM feedbacks
    SQL

    # Migrate emoji reactions
    execute <<~SQL
      INSERT INTO check_in_feedbacks (workout_check_in_id, author_id, emoji, created_at, updated_at)
      SELECT workout_check_in_id, author_id, emoji, created_at, updated_at
      FROM workout_reactions
    SQL

    drop_table :feedbacks
    drop_table :workout_reactions
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
