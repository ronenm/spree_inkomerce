Spree::Variant.class_eval do
  has_one :ink_button, class_name: 'Spree::InkButton', dependent: :destroy, inverse_of: :variant
  
  delegate :minimum_price_in, :minimum_price, :set_minimum_price, :minimum_price=, to: :ink_button, allow_nil: true

  delegate :url, :uid, :published, :publish, :url=, :uid=, :published=, :publish=, to: :ink_button, prefix: true

  after_initialize :ensure_ink_button

  after_save :update_ink_button
  
  validate :check_ink_button_values
  
  def ink_name
    option_values.exists? ? "#{name} (#{options_text})" : name
  end
  
  def ink_button_allow_publish?
    ink_button_publish && (product.nil? || product.master.nil? || product.ink_button_publish)
  end
  
  private
  
  def ensure_ink_button
    self.ink_button = Spree::InkButton.new(published: false) unless ink_button
  end

  def update_ink_button
    if ink_button_allow_publish?
      if ink_button.updated_at < self.product.updated_at
        store = Spree::InkomerceStore.new
        if store
          store.create_product(self, true)
          ink_button.save
        end
      end
    else
      self.ink_button_published = false
    end
  end

  def check_ink_button_values
    if ink_button.publish.nil?
      # This marks a new variant
      if is_master
        ink_button.publish = false
      else
        if product && product.master
          master = product.master
          ink_button.maximum_discount = master.ink_button.maximum_discount if ink_button.maximum_discount.nil?
          ink_button.publish = true
        end
      end
    end
  end

end
