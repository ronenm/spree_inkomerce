module Spree
  class Promotion
    module Actions
      class CreateInkAdjustments < CreateItemAdjustments
        include Spree::Core::CalculatedAdjustments
       
        # Perform caching of ink_deal since it is used allot in this adjustment
        def ink_deal
          if @ink_deal
            @ink_deal
          else
            @ink_deal = promotion.ink_deal
          end
        end
       
        def eligible?(originator)
          promotion.eligible? && ink_deal.active?
        end
        
        def ink_button
          ink_deal.ink_button
        end
        
        def apply(order)
          return 0 unless ink_deal.active?
          counter = 0
          order.line_items.where(variant_id: ink_button.variant_id).each do |line_item|
            # This may seen inefficient, however there should only one such line_item
            if line_item.adjustments.where(source_type: self.class.to_s, source_id: self.id).exists?
              counter += 1
            else
              counter += 1 if self.create_adjustment(order,line_item)
            end
          end
        end
  
        # I had to totally override this method just to change the
        # labeling!!!
        def create_adjustment(order,line_item)
          amount = self.compute_amount(line_item)
          return false if amount == 0
          self.adjustments.create!(
            amount: amount,
            adjustable: line_item,
            order: order,
            label: "#{Spree.t(:ink_deal)} - #{ink_button.variant.ink_name}",
          )
          true
        end
    
        def compute_amount(adjustable)
          ensure_action_has_calculator
          super
        end
    
        def close
          ink_deal.close
          super
        end
    
        private
                
        def ensure_action_has_calculator
          return if self.calculator
          self.calculator = Calculator::InkDeal.new
        end
      end
    end
  end
end