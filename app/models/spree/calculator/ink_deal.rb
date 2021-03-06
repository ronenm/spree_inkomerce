require_dependency 'spree/calculator'

module Spree
  class Calculator < ActiveRecord::Base
    class InkDeal < Calculator

      def ink_deal
        calculable.ink_deal
      end

      def self.description
        Spree.t(:ink_deal_calculator)
      end

      def compute(line_item)
        tot_disc = ink_deal.discount * line_item.quantity
        item_total = line_item.amount
        tot_disc > item_total ? item_total : tot_disc
      end

    end
  end
end