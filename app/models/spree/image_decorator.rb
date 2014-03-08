Spree::Image.class_eval do 
  after_save :update_ink_images
  
  private
  
  def update_ink_images
    if viewable_type=='Spree::Variant'
      variant = viewable
      if variant.ink_button && variant.ink_button.published?
        Spree::InkomerceStore.new.update_product_image(variant,self)
      end
      
    end
    
  end
end
