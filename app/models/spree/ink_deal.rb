module Spree
  class InkDeal < ActiveRecord::Base
    acts_as_paranoid
    
    belongs_to :ink_button
    
    validates :ink_button_id, presence: true
    validates :uid, presence: true, uniqueness: true
    validates :discount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: false
    
    before_validation :populae_ink_deal_data
    
    belongs_to :promotion
      
    def apply(args)
      promotion.actions.first.apply(args)
    end
    
    # This is required in order to support population of the deal
    def nuid
      self.uid
    end
    
    def buid
      ink_button.uid
    end
    
    def close
      Spree::InkomerceStore.new.close_deal(self) and save
    end
    
    def calculate_expiration
      Time.now + 12.hours
    end
    
    private
    
    def populae_ink_deal_data
      if discount.nil?
        store = Spree::InkomerceStore.new  # InK Store must already been setup for this to work
        store.populate_deal_data(self) or return(false)
      end
      
      # Now create the promotion (if it doesn't exist)
      unless promotion
        self.promotion = Spree::Promotion.new(
          name: 'InKomerce Deal',
          code: uid,
          advertise: false,
          description: "Internal InKomerce deal promotion",
          expires_at: calculate_expiration,
        )
      end
      if promotion.actions.none?
        promotion.actions << Spree::Promotion::Actions::CreateInkAdjustments.new
      end
      
    end
    
  end
end