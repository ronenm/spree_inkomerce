module SpreeInkomerce
  class Engine < Rails::Engine
    require 'spree/core'
    isolate_namespace Spree
    engine_name 'spree_inkomerce'

    config.autoload_paths += %W(#{config.root}/lib)

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    initializer "spree.inkomerce.preferences", :before => :load_config_initializers do |app|
      Spree::AppConfiguration.class_eval do
        preference :inkomerce_store_uid,          :string
        preference :inkomerce_store_token,        :string
        preference :inkomerce_site_type,           :string, :default => 'production'
        preference :can_default_maximum_discount, :integer
        #preference :inkit_button_logo_url,        :string, :default => "https://s3.amazonaws.com/inkomerce-assets/sellers-assets/ink_can_light_with_bg.png"
        preference :inkit_button_logo_url,        :string, :default => "https://s3.amazonaws.com/inkomerce-assets/sellers-assets/oj_icon_white.png"
      end
    end


    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/**/*_decorator*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
      Dir.glob(File.join(File.dirname(__FILE__), "../../app/models/spree/calculator/*.rb")) do |c|
        Rails.env.production? ? require(c) : load(c)
      end
      Dir.glob(File.join(File.dirname(__FILE__), "../../app/models/spree/promotion/actions/*.rb")) do |c|
        Rails.env.production? ? require(c) : load(c)
      end
    end

    config.to_prepare &method(:activate).to_proc
  end
end
