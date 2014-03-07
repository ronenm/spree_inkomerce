Spree::Promotion.class_eval do
  
  has_one :ink_deal, class_name: "Spree::InkDeal", dependent: :destroy
  
end
