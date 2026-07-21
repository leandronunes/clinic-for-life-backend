class CreateChatMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_messages do |t|
      t.references :student, null: false, foreign_key: true
      t.string :sender_role, null: false
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.text :body, null: false
      t.datetime :read_at

      t.timestamps
    end

    add_index :chat_messages, [ :student_id, :created_at ]
    add_index :chat_messages, [ :student_id, :read_at ]
  end
end
