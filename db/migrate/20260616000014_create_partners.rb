class CreatePartners < ActiveRecord::Migration[8.1]
  def change
    create_table :partners do |t|
      t.string :name, null: false
      t.string :logo_url
      t.string :category, null: false
      t.text :description
      t.string :coupon
      t.string :link

      t.timestamps
    end

    add_index :partners, :category
  end
end
