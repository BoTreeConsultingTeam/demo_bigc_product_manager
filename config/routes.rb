Rails.application.routes.draw do
  root "home#index"
  get '/auth/:name/callback' => 'omniauths#callback'
  get '/load' => 'omniauths#load'
  get '/uninstall' => 'omniauths#uninstall'
end
