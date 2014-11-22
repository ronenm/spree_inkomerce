require "InKomerce_API_v1"

module Spree
  class InkomercePartner
    include ActiveModel::Model
    
    attr_reader :partner_record, :uid, :token, :partner_proxy_connector
    
    cattr_accessor :partner_proxy_connector  # No need to create more than one partner connector
    
    cattr_accessor :global_connector
  
    API_SITE = ENV.key?('INKOMERCE_SITE') ? ENV['INKOMERCE_SITE'].to_sym : :test
    PARTNER_UID = ENV['INKOMERCE_PARTNER_UID']
    PARTNER_TOKEN = ENV['INKOMERCE_PARTNER_TOKEN']
  
    def self.global_data
      if global_connector.nil?
        self.global_connector = InKomerceAPIV1::Global.new(API_SITE)
      end
      self.global_connector
    end
  
  
    # These are just a "convenience" methods
    def partner_proxy_connector
      self.class.partner_proxy_connector
    end
    
    def id
      uid
    end
    
    def self.exists?
      PARTNER_UID && PARTNER_TOKEN
    end
    
    def persisted?
      self.class.exists?
    end
      
    def uid
      partner_proxy_connector.uid
    end
    
    def token
      partner_proxy_connector.token
    end
          
    def self.connect
      self.partner_proxy_connector = connector = InKomerceAPIV1::PartnerProxy.connect(PARTNER_UID,PARTNER_TOKEN,API_SITE)
      raise "Unable to connect to InKomerce API" if connector.nil?
      raise "InKomerce API connection error - #{connector.partner_record[:error]}" if connector.partner_record[:error]
      raise "InKomerce API internal error!!!" if connector.partner_record[:partner].nil?
      self.partner_proxy_connector
    end
    
    def self.get_partner
      connector = partner_proxy_connector || connect
      connector.partner_record[:partner]
    end
    
    def partner
      self.class.get_partner
    end
    
    def self.load
      partner_proxy_connector and partner_proxy_connector.load or connect
    end
      
    def initialize(attributes={})
      super
      self.class.connect if persisted? && !partner_proxy_connector
    end
      
    def load
      self.class.load
    end
      
    def save
      raise "ERROR: At this stage you cannot save a partner_proxy data!"
    end
     
    delegate :ui_url, :create_affinity, :partner_record, :get_affinity_session, to: :partner_proxy_connector
  
  end
end