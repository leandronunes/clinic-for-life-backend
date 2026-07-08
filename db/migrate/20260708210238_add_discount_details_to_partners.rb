class AddDiscountDetailsToPartners < ActiveRecord::Migration[8.1]
  def change
    add_column :partners, :discount_details, :text
  end
end
