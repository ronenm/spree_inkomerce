module Spree
  class InkDeal < ActiveRecord::Base
    acts_as_paranoid
    
    belongs_to :ink_button
    
    validates :ink_button_id, presence: true
    validates :uid, presence: true
    validates :discount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: false
    
    include Spree::Core::CalculatedAdjustments
    
    has_many :adjustments, as: :source
    
    before_validation :ensure_action_has_calculator
    before_destroy :deals_with_adjustments
    
    def eligible?
      ink_button && ink_button.active?
    end
    
    # Calculate the amount to be used when creating an adjustment
    def compute_amount(calculable)
      self.calculator.compute(calculable, self)
    end
    
    def apply(order)
      return false unless active
      variant = ink_button.variant
      already_adjusted_line_items = [0] + self.adjustments.pluck(:adjustable_id)
      result = false
      order.line_items.where("id NOT IN (?)", already_adjusted_line_items).where(variant_id: variant).find_each do |line_item|
        current_result = self.create_adjustment(line_item, order)
        result ||= current_result
      end
      return result
    end
  
    def create_adjustment(adjustable, order)
      amount = self.compute_amount(adjustable)
      return false if amount == 0
      self.adjustments.create!(
        amount: amount,
        adjustable: adjustable,
        order: order,
        label: "#{Spree.t(:ink_deal)} (#{uid}) - #{line_item.name}",
      )
      true
    end
    
    def compute_amount(calculable)
      self.calculator.compute(calculable, self)
    end
    
    private
    
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