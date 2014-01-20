Spree::Product.class_eval do

  delegate_belongs_to :master, :minimum_price_in, :minimum_price, :set_minimum_price
  delegate_belongs_to :master, :ink_button_url, :ink_button_uid, :ink_button_published, :ink_button_publish

  after_save :ink_button_synchronize

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
  
  private
  
  def ink_button_synchronize
    if ink_button_publish && ink_negotiable?!=:all
      master.save
      if variants.any?
        variants.joins(:ink_button).where('spree_ink_buttons.publish' => [true,nil], 'spree_ink_buttons.published' => [false,nil]).
          readonly(false).each { |var| var.save }
      end
    elsif !ink_button_publish && ink_negotiable?
      if variants.any?
        variants.joins(:ink_button).where('spree_ink_buttons.published' => true).readonly(false).each do |var|
          var.save
        end
      else
        master.save
      end
    end
    
  end
end
