class RemoveHeightCmFromStudents < ActiveRecord::Migration[8.1]
  def change
    remove_column :students, :height_cm, :integer
  end
end
