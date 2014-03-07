class AddSpreePromotionRefToSpreeInkDeals < ActiveRecord::Migration
  def change
    add_reference :spree_ink_deals, :promotion, index: true
  end
end
