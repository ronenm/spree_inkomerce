class CreateSpreeInkDeals < ActiveRecord::Migration
  def change
    create_table :spree_ink_deals do |t|
      t.references :ink_button, index: true
      t.references :line_item, index: {:unique=>true}
      t.decimal :discount, :precision => 10, :scale => 2
      t.boolean :active
      t.string :uid, null: false

      t.timestamps
    end
  end
end
