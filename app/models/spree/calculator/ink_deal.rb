require_dependency 'spree/calculator'

module Spree
  class Calculator < ActiveRecord::Base
    class InkDeal < Calculator

      def self.description
        Spree.t(:ink_deal_calculator)
      end

      def compute(line_item, ink_deal)
        # Ensure that there is no negative amount
        return [ink_deal.discount * line_item.quantity. line_item.amount].min * -1
      end

    end
  end
end