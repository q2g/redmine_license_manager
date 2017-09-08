Rails.application.routes.draw do
  
  #get   "/getlef/:serial/:checksum" 
  get "/lefupdate/update_lef.asp" => "rlm_licenses#index", as: :get_lef
  
end