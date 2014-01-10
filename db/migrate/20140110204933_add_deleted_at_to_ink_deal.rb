class AddDeletedAtToInkDeal < ActiveRecord::Migration
  def change
    add_column :spree_ink_deals, :deleted_at, :datetime
  end
end
