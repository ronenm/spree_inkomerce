class RemoveSpreeInkDealLineItem < ActiveRecord::Migration
  def change
    remove_reference :spree_ink_deals, :line_item
  end
end
