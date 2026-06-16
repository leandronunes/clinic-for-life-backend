class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :role, null: false, default: "student"
      t.string :avatar_url
      t.references :trainer, null: true, foreign_key: true
      t.references :student, null: true, foreign_key: true
      t.boolean :mfa_enabled, null: false, default: false
      t.datetime :terms_accepted_at
      t.datetime :last_login_at

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :role
  end
end
