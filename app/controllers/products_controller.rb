class ProductsController < ApplicationController
  def index
    all_products  = Bigcommerce::Product.all(connection: current_connection)
    @products = []
    all_products.each do |product|
        @products << OpenStruct.new(product)
    end
  end

  def show
    @product = Bigcommerce::Product.find(params[:id], connection: current_connection)
  end

  def new
  end

  def create
    @category = Bigcommerce::Category.all(connection: current_connection)[0]
    begin
      @product = Bigcommerce::Product.create(
        name: params[:name],
        type: 'physical',
        description: params[:description],
        price: params[:price],
        categories: [@category.id],
        availability: 'available',
        weight: params[:weight],
        connection: current_connection
      )
      redirect_to products_path
    rescue e
      Rails.logger.error(e)
    end

  end

  def destroy
    Bigcommerce::Product.destroy(params[:id], connection: current_connection)
    redirect_to products_path
  end
end
