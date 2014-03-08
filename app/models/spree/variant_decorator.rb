Spree::Variant.class_eval do
  has_one :ink_button, class_name: 'Spree::InkButton', dependent: :destroy, inverse_of: :variant
  
  delegate :minimum_price_in, :minimum_price, :set_minimum_price, :minimum_price=, :used_minimum_price, :used_minimum_price_in,
    to: :ink_button, allow_nil: true

  delegate :url, :uid, :published, :published?, :publish, :url=, :uid=, :published=, :publish=, to: :ink_button, prefix: true

  after_initialize :ensure_ink_button

  after_save :update_ink_button
  
  validate :check_ink_button_values

  scope :ink_publish, joins(:ink_button).where('spree_ink_buttons.publish' => true)
  
  scope :ink_published, joins(:ink_button).where('spree_ink_buttons.published' => true)
  
  scope :ink_publish_descrepency, joins(:ink_button).where('NOT (spree_ink_buttons.publish = spree_ink_buttons.published)')
  
  attr_accessor :update_ink_buttons_required
  
  def ink_name
    option_values.exists? ? "#{name} (#{options_text})" : name
  end
  
  def ink_button_allow_publish?
    Spree::InkomerceStore.exists? && (ink_button.publish.nil? || ink_button.publish) && (is_master? || product.nil? || product.master.nil? || product.ink_button_publish)
  end

  def ensure_ink_button
    begin
      self.ink_button = Spree::InkButton.new(published: false) unless ink_button
    rescue
      puts "ink_button not defined!"
    end
  end

  def update_ink_button
    if ink_button_allow_publish?
      if !ink_button.published? || update_ink_buttons_required
        store = Spree::InkomerceStore.new
        if store
          ink_button.save if ink_button.changed?
          self.reload
          store.create_product(self, true)
        end
      end
    else
      ink_button.published = false  
    end
    ink_button.save if ink_button.changed?
  end

  private
 
  def check_ink_button_values
    if ink_button.publish.nil?
      # This marks a new variant
      if is_master
        ink_button.publish = false
      else
        ink_button.publish = true if product && product.master
      end
    end
  end

end
