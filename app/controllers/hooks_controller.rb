# All webhooks generateed from Bigcommerce will be handled over here.
class HooksController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def product_created
    puts "<<<<<<<<<<< PRODUCT CREATED WEBHOOK INITIATED >>>>>>>>>>>>>>>"
    puts params
    render nothing: true, status: 200
  end
end
