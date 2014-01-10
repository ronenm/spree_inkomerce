Spree::Order.class_eval do

  # Mark all ink deals as non-active
  def finalize_with_ink_deals!
    finalize_without_ink_deals!
    self.adjustments.ink_deals.update_all(active: false)
  end
  alias_method_chain :finalize!, :ink_deals
  
end
