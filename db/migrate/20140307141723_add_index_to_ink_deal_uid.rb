class AddIndexToInkDealUid < ActiveRecord::Migration
  def change
    add_index :spree_ink_deals, :uid, unique: true
  end
end
