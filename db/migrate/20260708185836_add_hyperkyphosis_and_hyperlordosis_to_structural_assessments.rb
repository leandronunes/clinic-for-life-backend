class AddHyperkyphosisAndHyperlordosisToStructuralAssessments < ActiveRecord::Migration[8.1]
  def change
    add_column :structural_assessments, :hyperkyphosis, :boolean, null: false, default: false
    add_column :structural_assessments, :hyperlordosis, :boolean, null: false, default: false
  end
end
