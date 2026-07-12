class CreateFeedbacks < ActiveRecord::Migration[8.1]
  def change
    create_table :feedbacks do |t|
      t.references :student, null: false, foreign_key: true
      t.references :author, foreign_key: { to_table: :users }
      t.string :kind, null: false
      t.text :message, null: false
      t.timestamps
    end
    add_index :feedbacks, [ :student_id, :created_at ]
  end
end
