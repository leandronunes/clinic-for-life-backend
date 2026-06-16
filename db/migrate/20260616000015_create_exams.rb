class CreateExams < ActiveRecord::Migration[8.1]
  def change
    create_table :exams do |t|
      t.references :student, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.string :file_url, null: false
      t.string :content_type
      t.bigint :size
      t.datetime :uploaded_at, null: false

      t.timestamps
    end
  end
end
