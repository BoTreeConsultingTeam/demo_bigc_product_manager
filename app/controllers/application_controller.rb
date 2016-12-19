class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  after_filter :set_header_for_iframe
  helper_method :current_store

  private

  # require to remove X-Frame-Options to load Rails app in iframe on Bigcommerce
  def set_header_for_iframe
    response.headers.delete "X-Frame-Options"
  end

  def current_store
    if params['producer'].present?
      store_hash = params['producer'].split('/').last
      @current_store = Store.find_by(store_hash: store_hash)
      session[:store_id] = @current_store.id
    else
      @current_store = Store.last #Store.find(session[:store_id])
    end
    @current_store
  end
end
