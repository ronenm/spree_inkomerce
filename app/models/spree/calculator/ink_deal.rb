require_dependency 'spree/calculator'

module Spree
  class Calculator < ActiveRecord::Base
    class InkDeal < Calculator

      def self.description
        Spree.t(:ink_deal_calculator)
      end

      def compute(order, ink_deal)
        quantity = order.line_items.where(variant_id: ink_deal.ink_button.variant_id).sum(:quantity)
        tot_disc = ink_deal.discount * quantity
        tot_disc > order.item_total ? -order.item_total : -tot_disc
      end

    end
  end
end