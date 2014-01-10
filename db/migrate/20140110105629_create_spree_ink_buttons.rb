class CreateSpreeInkButtons < ActiveRecord::Migration
  def change
    create_table :spree_ink_buttons do |t|
      t.float :maximum_discount
      t.boolean :publish
      t.string :uid
      t.string :url
      t.boolean :published
      t.references :variant, index: {:unique=>true}

      t.timestamps
    end
    add_index :spree_ink_buttons, :uid, unique: true
  end
end
