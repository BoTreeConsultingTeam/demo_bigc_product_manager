class OmniauthsController < ApplicationController
  def callback
    auth = request.env['omniauth.auth']
    unless auth && auth[:extra][:raw_info][:context]
      return render_error("[install] Invalid credentials: #{JSON.pretty_generate(auth[:extra])}")
    end
    app_url  = ENV['APPLICATION_URL']
    email = auth[:info][:email]
    name = auth[:info][:name]
    store_hash = auth[:extra][:context].split('/')[1]
    token = auth[:credentials][:token].token
    scope = auth[:extra][:scopes]

    # Lookup store
    store = Store.where(store_hash: store_hash).first
    if store
      logger.info "[install] Updating token for store '#{store_hash}' with scope '#{scope}'"
      store.update(access_token: token, scope: scope)
      connection = Bigcommerce::Connection.build(Bigcommerce::Config.new(store_hash: store.store_hash, client_id: ENV['BC_CLIENT_ID'], access_token: store.access_token))
      # webhook1 = Bigcommerce::Webhook.create( scope: 'store/order/created',  destination: "#{app_url}/hooks/order_created",  connection: connection  )
      # webhook2 = Bigcommerce::Webhook.create( scope: 'store/shipment/created',  destination: "#{app_url}/hooks/shipment_created",  connection: connection  )

    else
      logger.info "[install] Installing app for store '#{store_hash}' with admin '#{email}'"
      store = Store.create(store_hash: store_hash, access_token: token, scope: scope, email: email, username: name)
      if store.present?
        connection = Bigcommerce::Connection.build(Bigcommerce::Config.new(store_hash: store.store_hash, client_id: ENV['BC_CLIENT_ID'], access_token: store.access_token))
        # webhook1 = Bigcommerce::Webhook.create( scope: 'store/order/created',  destination: "#{app_url}/hooks/order_created",  connection: connection  )
        # webhook2 = Bigcommerce::Webhook.create( scope: 'store/shipment/created',  destination: "#{app_url}/hooks/shipment_created",  connection: connection  )
      end
      session[:store_id] = store.id
      logo = Bigcommerce::StoreInfo.info(connection: connection)[:logo]
      session[:store_logo] = logo.present? ? logo[:url] : 'assets/default_logo.png'
    end
    render 'home/index', status: 200
  end

  def uninstall
    payload = parse_signed_payload
    store = Store.find_by(store_hash: payload["store_hash"])
    store.destroy if store.present?
    Rails.logger.debug "Store Removed successfully"
    render nothing: true, status: 200
  end

  def load
    payload = parse_signed_payload
    @payload = payload
    return render_error('[load] Invalid payload signature!') unless payload
    email = payload['user']['email']
    @email = email
    store_hash = payload['store_hash']
    # Lookup store
    @store = Store.find_by(store_hash: store_hash)
    connection = Bigcommerce::Connection.build(Bigcommerce::Config.new(store_hash: @store.store_hash, client_id: ENV['BC_CLIENT_ID'], access_token: @store.access_token))
    return render_error("[load] Store not found!") unless @store
    logger.info "[load] Loading app for user '#{email}' on store '#{store_hash}'"
    session[:store_id] = @store.id
    logo = Bigcommerce::StoreInfo.info(connection: connection)[:logo]
    session[:store_logo] = logo.present? ? logo[:url] : 'assets/default_logo.png'
    render 'home/index', status: 200
  end

  private

  def parse_signed_payload
    signed_payload = params[:signed_payload]
    message_parts = signed_payload.split('.')
    encoded_json_payload = message_parts[0]
    encoded_hmac_signature = message_parts[1]
    payload = Base64.decode64(encoded_json_payload)
    provided_signature = Base64.decode64(encoded_hmac_signature)
    expected_signature = sign_payload(bc_client_secret, payload)
    if secure_compare(expected_signature, provided_signature)
      return JSON.parse(payload)
    end
    nil
  end

  def sign_payload(secret, payload)
    OpenSSL::HMAC::hexdigest('sha256', secret, payload)
  end

  def secure_compare(a, b)
    binding.pry
    return false if a.blank? || b.blank? || a.bytesize != b.bytesize
    l = a.unpack "C#{a.bytesize}"

    res = 0
    b.each_byte { |byte| res |= byte ^ l.shift }
    res == er_error(e)
    logger.warn "ERROR: #{e}"
    @error = e

    raise e
  end

  def bc_client_id
    ENV['BC_CLIENT_ID']
  end

  # Get client secret from env
  def bc_client_secret
    ENV['BC_CLIENT_SECRET']
  end

# Get the API url from env
  def bc_api_url
    ENV['BC_API_ENDPOINT'] || 'https://api.bigcommerce.com'
  end

  # Full url to this app
  def app_url
    ENV['APP_URL']
  end

  # The scopes we are requesting (must match what is requested in
  # Developer Portal).
  def scopes
    ENV.fetch('SCOPES', 'store_v2_products')
  end

  def secure_compare(a, b)
    return false if a.blank? || b.blank? || a.bytesize != b.bytesize
    l = a.unpack "C#{a.bytesize}"

    res = 0
    b.each_byte { |byte| res |= byte ^ l.shift }
    res == 0
  end

  def render_error(e)
    logger.warn "ERROR: #{e}"
    @error = e

    raise e
  end
end
