Spree::Adjustment.class_eval do

  scope :ink_deals, -> { where(:source_type => 'Spree::InkDeal') }

end