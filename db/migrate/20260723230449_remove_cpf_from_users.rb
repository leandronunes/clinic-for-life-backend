class RemoveCpfFromUsers < ActiveRecord::Migration[8.1]
  def change
    remove_column :users, :cpf, :string
  end
end
