class AddCpfToStudents < ActiveRecord::Migration[8.1]
  def change
    add_column :students, :cpf, :string
    add_index :students, :cpf, unique: true
  end
end
