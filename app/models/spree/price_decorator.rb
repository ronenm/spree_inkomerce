Spree::Price.class_eval do 
  after_save :update_ink_button
  
  private
  
  def update_ink_button
    ink_button = variant.ink_button
    if variant.ink_button && ink_button.published? && !variant.product.ink_fields_changed?
      store = Spree::InkomerceStore.new
      store.update_prices(variant)
      ink_button.save if ink_button.changed?
    end
  end
end
