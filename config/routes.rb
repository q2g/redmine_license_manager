Rails.application.routes.draw do
  
  get "/lefupdate/update_lef.asp" => "rlm_licenses#index", as: :get_lef
  get "/lefupdate/update_lef.json" => "rlm_licenses#get_lefs_json", as: :get_lef_json
  
  namespace :rlm_licenses do
    patch :invoice_licenses
    patch :update_lef
    patch :merge
    post :split
  end
  
end