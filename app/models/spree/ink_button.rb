module Spree
  class InkButton < ActiveRecord::Base
    acts_as_paranoid
    
    belongs_to :variant
  
    has_many :ink_deals, class_name: 'Spree::InkDeal', dependent: :destroy, inverse_of: :ink_button
  
    validates :uid, uniqueness: true, unless: "uid.nil?"
    validates :variant_id, presence: true, uniqueness: true
    validates :maximum_discount, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
    
    # The minimum price is a fraction of the original price
    # This way we can support prices in different currencies
    # The limitation is that minimum price discount in percent is equal with all currencies
    # Developer can change that if required
    def minimum_price_in(currency)
      orig_price = variant.amount_in(currency)
      return nil if orig_price.nil? || maximum_discount.nil? # The caller will use the default maximum_discount
      Spree::Money.new(orig_price*(1.0-maximum_discount),currency: currency).money.to_s
    end
  
    def minimum_price
      minimum_price_in(Spree::Config.currency)
    end
  
    # This is the claculation that is used to determine the minimum price when sending to InKomerce!
    def used_minimum_price_in(currency)
      orig_price = variant.amount_in(currency)
      return nil if orig_price.nil?
      max_disc = maximum_discount
      # If there is no maximum_discount on the variant take it from the master variant
      max_disc = variant.product.master.ink_button.maximum_discount if max_disc.nil? && !variant.is_master && variant.product.master
      # If there is no maximum_discount on the variant and nor on the master we will take it from the global setting
      max_disc = Spree::Config.can_default_maximum_discount.to_i/100.0 if max_disc.nil?
      return nil if max_disc.nil? # The caller will use the default maximum_discount
      Spree::Money.new(orig_price*(1.0-max_disc),currency: currency).to_s
    end
  
    def used_minimum_price
      used_minimum_price_in(Spree::Config.currency)
    end
  
    def set_minimum_price(price,currency)
      price_rec = Spree::Price.new(price: price, currency: currency)
      price = price_rec.amount
      orig_price = variant.amount_in(currency)
      self.maximum_discount = price.nil? || orig_price.nil? || price<1 || orig_price<1 ? nil : 1.0-price/orig_price
      price
    end
  
    def minimum_price=(price)
      set_minimum_price(price,Spree::Config.currency)
    end
  
  end
end
