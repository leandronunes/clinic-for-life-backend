class AddPartnerCardEnabledToStudents < ActiveRecord::Migration[8.1]
  def change
    add_column :students, :partner_card_enabled, :boolean, null: false, default: true
  end
end
