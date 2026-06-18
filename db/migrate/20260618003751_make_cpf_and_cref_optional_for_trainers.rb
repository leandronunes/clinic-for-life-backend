class MakeCpfAndCrefOptionalForTrainers < ActiveRecord::Migration[8.1]
  def change
    change_column_null :trainers, :cpf, true
    change_column_null :trainers, :cref, true
  end
end
