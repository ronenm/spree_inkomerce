require "InKomerce_API_v1"

module Spree
  class InkoerceStore
    include ActiveModel::Model
    
    attr_accessor :name, :default_category_id, :store_url, :success_uri, :cancel_uri, :currency,
                  :language, :default_maximum_discount, :button_logo_url, :api_client_id, :api_client_secret
    
    SYNC_ATTRIBUTES = [:name, :store_url, :success_uri, :cancel_uri, :currency, :language]
    
    attr_reader :default_category, :uid, :token
    
    cattr_accessor :store_connector  # No need to create more than one store connector
    cattr_accessor :global_connector  # No need to create more than one global connector
    
    def id
      uid
    end
    
    def persisted?
      !uid.nil?
    end
    
    def default_category
      unless store_connector.nil?
        store_connector.store_rec[:default_category][:name]
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
      self.store_connector = InKomerce_API_v1::Store.create(client_id,client_secret,Spree::Config.inkomerce_site_type.to_sym,data)
      Spree::Config.inkomerce_store_uid = self.store_connector.uid
      Spree::Config.inkomerce_store_token = self.store_connector.token
    end
    
    def self.connect
      self.store_connector = InKomerceAPIV1::Store.connect(Spree::Config.inkomerce_store_uid,
                                                           Spree::Config.inkomerce_store_token,
                                                           Spree::Config.inkomerce_site_type.to_sym)
      raise "Unable to connect to InKomerce API" if connector.nil?
      raise "InKomerce API connection error - #{connector.store_rec[:error]}" if connector.store_rec[:error]
      raise "InKomerce API internal error!!!" connector.store_rec[:store].nil?
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
      sync if persisted?
      super
    end
    
    def sync
      store = self.class.get_store
      SYNC_ATTRIBUTES.each { |attr| attributes[attr] = store[attr] unless attributes[attr] }
      attributes[:default_category_id] = store[:default_category][:id] unless attributes[:default_category_id]
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
        self.global_connector = InKomerceAPIV1::global.new(Spree::Config.inkomerce_site_type.to_sym)
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
    
  end
end