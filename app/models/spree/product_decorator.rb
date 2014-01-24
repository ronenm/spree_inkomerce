Spree::Product.class_eval do

  delegate_belongs_to :master, :minimum_price_in, :minimum_price, :set_minimum_price, :minimum_price=,
                      :used_minimum_price, :used_minimum_price_in
  delegate_belongs_to :master, :ink_button_url, :ink_button_uid, :ink_button_published, :ink_button_publish, :ink_button_publish=

  after_save :ink_button_synchronize

  after_validation :ink_button_unmark_published, if: :ink_fields_changed?

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

  def ink_fields_changed?
    name_changed? || description_changed?
  end
  
  def ink_button_unmark_published
    if variants.any?
      Spree::InkButton.where(variant_id: variants.pluck(:id)).update_all(published: false)
    else
      master.ink_button.update(published: false)
    end
  end
  
  def ink_button_synchronize
    master.ink_button.save if master.ink_button.changed?
    if ink_button_publish && ink_negotiable?!=:all
      if variants.any?
        variants.joins(:ink_button).where('spree_ink_buttons.publish' => [true,nil], 'spree_ink_buttons.published' => [false,nil]).
          readonly(false).each { |var| var.save }
      else
        master.save
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
