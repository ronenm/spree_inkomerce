module Spree
  class InkDeal < ActiveRecord::Base
    acts_as_paranoid
    
    belongs_to :ink_button
    
    validates :ink_button_id, presence: true
    validates :uid, presence: true, uniqueness: true
    validates :discount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: false
    
    include Spree::Core::CalculatedAdjustments
    
    has_many :adjustments, as: :originator
    
    before_validation :populae_ink_deal_data
    before_destroy :deals_with_adjustments
    
    def eligible?(originator)
      active?
    end
    
    # Calculate the amount to be used when creating an adjustment
    def compute_amount(calculable)
      self.calculator.compute(calculable, self)
    end
    
    def apply(order)
      return false unless active
      return true if order.adjustments.where(originator_type: self.class.to_s, originator_id: self.id).exists?
      if order.line_items.where(variant_id: ink_button.variant_id).exists?
        return self.create_adjustment(order)
      else
        return false
      end
    end
  
    def create_adjustment(order)
      order.update_totals
      amount = self.compute_amount(order)
      return false if amount == 0
      self.adjustments.create!(
        amount: amount,
        adjustable: order,
        source: order,
        order: order,
        label: "#{Spree.t(:ink_deal)} (#{uid}) - #{ink_button.variant.ink_name}",
      )
      true
    end
    
    def compute_amount(calculable)
      ensure_action_has_calculator
      self.calculator.compute(calculable, self)
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
    
    private
    
    def populae_ink_deal_data
      if discount.nil?
        store = Spree::InkomerceStore.new  # InK Store must already been setup for this to work
        store.populate_deal_data(self) or return(false)
      end
      ensure_action_has_calculator
    end
    
    def ensure_action_has_calculator
      return if self.calculator
      self.calculator = Calculator::InkDeal.new
    end

    def deals_with_adjustments
      adjustment_scope = self.adjustments.joins("LEFT OUTER JOIN spree_orders ON spree_orders.id = spree_adjustments.order_id")
      # For incomplete orders, remove the adjustment completely.
      adjustment_scope.where("spree_orders.completed_at IS NULL").readonly(false).destroy_all

      # For complete orders, the source will be invalid.
      # Therefore we nullify the source_id, leaving the adjustment in place.
      # This would mean that the order's total is not altered at all.
      adjustment_scope.where("spree_orders.completed_at IS NOT NULL").update_all("source_id = NULL")
    end

  end
end