require "InKomerce_API_v1"

module Spree
  class InkomerceStore
    include ActiveModel::Model
    
    attr_accessor :name, :default_category_id, :store_url, :success_uri, :cancel_uri, :currency,
                  :locale, :default_maximum_discount, :button_logo_url, :api_client_id, :api_client_secret
    
    SYNC_ATTRIBUTES = [:name, :store_url, :success_uri, :cancel_uri, :currency, :locale]

    DEFAULT_ATTRIBUTES_SETTING = {
      store_url: :site_url,
      currency: :currency,
      success_uri: 'ink/success',
      cancel_uri: 'ink/cancel',
      name: :site_name,
      button_logo_url: "https://s3.amazonaws.com/inkomerce-assets/sellers-assets/ink_can_light_with_bg.png",
      locale: 'en'
    }

    
    attr_reader :default_category, :uid, :token
    
    cattr_accessor :store_connector  # No need to create more than one store connector
    cattr_accessor :global_connector  # No need to create more than one global connector
    
    
    
    def id
      uid
    end
    
    def persisted?
      !(uid.nil? || uid=="")
    end
    
    def default_category
      unless store_connector.nil?
        store_connector.store_rec[:store][:default_category][:name]
      end
    end
    
    def uid
      Spree::Config.inkomerce_store_uid
    end
    
    def token
      Spree::Config.inkomerce_store_token
    end
    
    def default_maximum_discount
      Spree::Config.can_default_maximum_discount
    end
    
    def default_maximum_discount=(disc)
      Spree::Config.can_default_maximum_discount = disc
    end
    
    def button_logo_url
      Spree::Config.inkit_button_logo_url
    end
    
    def button_logo_url=(url)
      Spree::Config.inkit_button_logo_url = url
    end
    
    def self.create_store(client_id,client_secret,data)
      self.store_connector = InKomerceAPIV1::Store.create(client_id,client_secret,Spree::Config.inkomerce_site_type.to_sym,data)
      Spree::Config.inkomerce_store_uid = self.store_connector.uid
      Spree::Config.inkomerce_store_token = self.store_connector.token
    end
    
    def self.connect
      self.store_connector = connector = InKomerceAPIV1::Store.connect(Spree::Config.inkomerce_store_uid,
                                                           Spree::Config.inkomerce_store_token,
                                                           Spree::Config.inkomerce_site_type.to_sym)
      raise "Unable to connect to InKomerce API" if connector.nil?
      raise "InKomerce API connection error - #{connector.store_rec[:error]}" if connector.store_rec[:error]
      raise "InKomerce API internal error!!!" if connector.store_rec[:store].nil?
      self.store_connector
    end
    
    def self.replace_token(client_id,client_secret)
      connector = store_connector || connect
      connector.replace_token(client_id,client_id)
      Spree::Config.inkomerce_store_token = connector.token
    end
    
    def self.get_store
      connector = store_connector || connect
      connector.store_rec[:store]
    end
    
    def self.load
      store_connector and store_connector.load or connect
    end
    
    def initialize(attributes={})
      super
      sync if persisted?
      DEFAULT_ATTRIBUTES_SETTING.each do |key,val|
        unless send(key)
          send("#{key}=",val.is_a?(Symbol) ? Spree::Config.get_preference(val) : val)
        end
      end
      if s_url = self.store_url
        s_url.insert(0,"http://") unless s_url =~ /^https?:\/\//
        s_url.insert(-1,"/") unless s_url[-1] == '/'
        self.store_url = s_url
      end
    end
    
    
    def sync
      store = self.class.get_store
      SYNC_ATTRIBUTES.each { |attr| send("#{attr}=",store[attr]) unless send(attr) }
      self.default_category_id = store[:default_category][:id] unless self.default_category_id
    end
    
    def load
      self.class.load
      sync
    end
    
    # This is different than the active record implementation
    def changes
      if persisted?
        store = self.class.get_store
        changed_attrs = SYNC_ATTRIBUTES.select { |attr| send(attr) != store[attr] }
        changed_attrs << :default_category_id if default_category_id!=store[:default_category][:id]
        return changed_attrs
      else
        # All attributes have changed ;-)
        SYNC_ATTRIBUTES
      end
    end
    
    def save
      if valid?
        if persisted?
          changed_attrs = changes
          unless changed_attrs.empty?
            data = {}
            changed_attrs.each {|attr| data[attr] = send(attr) }
            self.class.store_connector.update(data)
            load
          end
        else
          data = {}
          SYNC_ATTRIBUTES.each { |attr| data[attr] = send(attr) }
          data[:default_category_id] = self.default_category_id
          self.class.create_store(api_client_id, api_client_secret, data)
          sync
        end
      end
    end
    
    def replace_token
      raise "Missing api_client_id or api_client_secret" unless api_client_id and api_client_secret
      self.class.replace_token(api_client_id,api_client_secret)
    end
    
    # Some global searches...
    def self.global
      if global_connector.nil?
        self.global_connector = InKomerceAPIV1::Global.new(Spree::Config.inkomerce_site_type.to_sym)
      end
      self.global_connector
    end
    
    # Hash the global searches
    cattr_accessor :categories_hash, :currencies_hash
    
    def self.categories(params = nil)
      if params.nil? 
        return categories_hash if categories_hash
        self.categories_hash = global.get_categories
      else
        global.get_categories(params)
      end
    end
    
    def self.currencies(params = nil)
      if params.nil? 
        return currencies_hash if currencies_hash
        self.currencies_hash = global.get_currencies
      else
        global.get_currencies(params)
      end
    end
    
    # Now for the setup
    def set_taxon(taxon)
      self.class.store_connector.create_taxonomy(taxon.id,name: taxon.name, parent_rid: taxon.parent_id)
    end
    
    def remove_taxon(taxon)
      # This is not supported by API, just ignore
    end
    
    # Create/Update a product (and its variants) or a single variant
    # At this stage every variant is a seperate product in InKomerce
    # TODO: Support products for which all variants are of the same price
    #   allow_override: false - if product exists return error, true - if product exists update it with new information
    def create_product(prod_or_var,allow_override=false)
      if prod_or_var.is_a?(Spree::Product)
        if prod_or_var.variants.empty?
          return create_product(prod_or_var.master,allow_override)
        else
          res = true
          prod_or_var.variants.each {|v| res &&= create_product(v,allow_override) }
          return res
        end
      end
      # Now we are in variants space
      title = prod_or_var.name
      title.insert(-1," (#{prod_or_var.options_text})") if prod_or_var.option_values.exists?
      price = prod_or_var.price_in(self.currency)
      return false if price.nil?
      offer = price.amount
      min_price = prod_or_var.try(:minimum_price_in,self.currency)
      min_price = min_price && min_price.amount || offer*(1.0-self.default_maximum_discount.to_i/100.0)
      ink_prod_rec = {
        rid: prod_or_var.id.to_s,
        title: title,
        description: prod_or_var.description,
        offer: offer.to_s,
        minimum_price: min_price.to_s,
        taxonomies_rids: prod_or_var.product.taxons.pluck(:id).join(", "),
        sku: prod_or_var.sku,
        images_urls: prod_or_var.images.map { |i| i.attachment.url(:original) },
        allow_override: allow_override
      }
      puts "*** #{ink_prod_rec} ****\n"
      ret_rec = self.class.store_connector.create_product(ink_prod_rec)
      if ret_rec.key?(:store_product)
        prod_or_var.try(:ink_button_uid=,ret_rec[:store_product][:button_uid])
        prod_or_var.try(:ink_button_url=,ret_rec[:store_product][:button_url])
        prod_or_var.try(:ink_button_published=,true)
        return true
      else
        self.errors.add(:general,ret_rec.is_a?(Hash) && ret_rec[:error] || "Unable to publish product to InKomerce")
        return false
      end
    end
    
    
  end
end