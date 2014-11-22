module Spree
  class InkomerceController < Spree::StoreController
    
    rescue_from ActiveRecord::RecordNotFound, :with => :render_404
    helper 'spree/products', 'spree/orders'
    
    def negotiate
      if params[:buid].nil?
        redirect_to unauthorized_path
        return
      end
      
      button = Spree::InkButton.find_by!(uid: params[:buid])
      
      partner = Spree::InkomercePartner.new
      
      user_affinity_token = session[:inkomerce_user_affinity_token]
      if user_affinity_token.nil?
        user_affinity_token = partner.create_affinity
        user_affinity_token = user_affinity_token[:user_affinity][:token]
        redirect_to unauthorized_path if user_affinity_token.nil?
        session[:inkomerce_user_affinity_token] = user_affinity_token
      end
      
      session_token_rec = partner.get_affinity_session(user_affinity_token)
      
      url = partner.ui_url('negotiations/new',buid: button.uid, session_token: session_token_rec[:session][:token])
      puts "PATH = #{url}\n"
      redirect_to url
    end
    
    def success
      if params[:buid].nil? || params[:nuid].nil?
        redirect_to unauthorized_path
        return
      end
      
      button = Spree::InkButton.find_by!(uid: params[:buid])
      
      deal = Spree::InkDeal.find_by(uid: params[:nuid])
      if deal && !deal.active
        redirect_to unauthorized_path
        return
      elsif !deal
        deal = button.ink_deals.create(uid: params[:nuid])
        deal.save
      end
      
      # Create order if necessary and add variant and deal
      populator = Spree::OrderPopulator.new(current_order(create_order_if_necessary: true), current_currency)
      if populator.populate(button.variant_id, 1)
        deal.apply(current_order)
        current_order.ensure_updated_shipments
        current_order.update!
        respond_with(@order) do |format|
          format.html { redirect_to cart_path }
        end
      else
        flash[:error] = populator.errors.full_messages.join(" ")
        redirect_to :back
      end
      
    end
    
    def cancel
      button = params[:buid] ? Spree::InkButton.find_by!(uid: params[:buid]) : nil
      redirect_to button.variant.product
    end
    
  end
end
