Spree::Product.class_eval do

  delegate_belongs_to :master, :minimum_price_in, :minimum_price, :set_minimum_price
  delegate_belongs_to :master, :ink_button_url, :ink_button_uid, :ink_button_published, :ink_button_publish

end
