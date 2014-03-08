Spree::Product.class_eval do

  delegate_belongs_to :master, :minimum_price_in, :minimum_price, :set_minimum_price, :minimum_price=,
                      :used_minimum_price, :used_minimum_price_in
  delegate_belongs_to :master, :ink_button_url, :ink_button_uid, :ink_button_published, :ink_button_publish, :ink_button_publish=

  after_save :ink_button_synchronize

  after_validation :ink_button_mark_for_update, if: :ink_fields_changed?

  attr_accessor :update_ink_buttons_required

  # This is used to claculate whther a product is negotiable (in which case we may
  # add an indifcator in the products list of its availability for negotiation)
  # It either return false (no negotiation at all), all (all varianets are negotiable)
  # or :some (some of the variants are negotiable)
  def ink_negotiable?
    if has_variants?
      all_counter = variants.count
      neg_counter = variants.ink_publish.where('spree_ink_buttons.published' => true).count
    else
      all_counter = 1
      neg_counter = ink_button_published ? 1 : 0
    end
    neg_counter>0 and (neg_counter>=all_counter) ? :all : :some
  end
  

  def ink_fields_changed?
    name_changed? || description_changed? || master.ink_button.changed?
  end
  
  def ink_button_mark_for_update
    self.update_ink_buttons_required = true
  end
  
  private

  def ink_button_synchronize
    master.ink_button.save if master.ink_button.changed?
    if update_ink_buttons_required
      if has_variants?
        variants.each do |var|
          var.update_ink_buttons_required = true
          var.save
        end
      else
        master.update_ink_buttons_required = true
        master.save 
      end
    end
  end
end
