Spree::Variant.class_eval do
  has_one :ink_button, class_name: 'Spree::InkButton', dependent: :destroy, inverse_of: :variant
  
  delegate :minimum_price_in, :minimum_price, :set_minimum_price, :minimum_price=, to: :ink_button, allow_nil: true

  delegate :url, :uid, :published, :publish, :url=, :uid=, :published=, :publish=, to: :ink_button, prefix: true

  after_initialize :ensure_ink_button

  after_save :update_ink_button
  
  validate :check_ink_button_values
  
  private
  
  def ensure_ink_button
    self.ink_button = Spree::InkButton.new(published: false) unless ink_button
  end

  def update_ink_button
    if ink_button_publish && ink_button.updated_at < self.product.updated_at
      store = Spree::InkomerceStore.new
      if store
        store.create_product(self, true)
        ink_button.save
      end
    end
  end

  def check_ink_button_values
    if ink_button.publish.nil?
      # This marks a new variant
      if is_master
        ink_button.publish = false
      else
        if Spree::Config[:require_master_price] 
          raise 'No master variant found to infer minimum price' unless (product && product.master)
          master = product.master
          ink_button.maximum_discount = master.ink_button.maximum_discount if ink_button.maximum_discount.nil?
          ink_button.publish = master.ink_button.publish
        end
      end
    end
  end

end
