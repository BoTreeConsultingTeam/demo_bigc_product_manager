Rails.application.config.middleware.use OmniAuth::Builder do
  provider :bigcommerce, ENV['BC_CLIENT_ID'], ENV['BC_CLIENT_SECRET']
end
