class AddCanSettingsToSpreeVariants < ActiveRecord::Migration
  def change
    add_column :spree_variants, :can_min_price, :decimal
    add_column :spree_variants, :can_publish, :boolean
  end
end
