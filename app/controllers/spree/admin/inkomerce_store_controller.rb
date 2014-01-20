module Spree
  module Admin
    class InkomerceStoreController < Spree::Admin::BaseController
      
      def edit
        @inkomerce_store = Spree::InkomerceStore.new
      end
      
      def update
        @inkomerce_store = Spree::InkomerceStore.new(params[:inkomerce_store])
        @inkomerce_store.save
        flash[:success] = Spree.t(:successfully_updated, :resource => Spree.t(:inkomerce_store))
        redirect_to admin_inkomerce_store_path
      end
      
      def renew_token
        @inkomerce_store = Spree::InkomerceStore.new
      end
      
      def replace_token
        @inkomerce_store = Spree::InkomerceStore.new(params[:inkomerce_store])
        @inkomerce_store.replace_token
        redirect_to admin_inkomerce_store_path
      end
      
    end
  end
end
