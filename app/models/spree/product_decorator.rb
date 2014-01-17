Spree::Product.class_eval do

  delegate_belongs_to :master, :minimum_price_in, :minimum_price, :set_minimum_price
  delegate_belongs_to :master, :ink_button_url, :ink_button_uid, :ink_button_published, :ink_button_publish

  def ink_negotiable?
    if variants.any?
      all_counter = variants.size
      neg_counter = variants.joins(:ink_button).where('spree_ink_buttons.published' => true).count
    else
      all_counter = 1
      neg_counter = ink_button_published ? 1 : 0
    end
    neg_counter>0 and (neg_counter>=all_counter) ? :all : :some
  end
end
