Rails.application.routes.draw do
  
  get   "/getlef/:serial/:checksum" => "rlm_licenses#index", as: :get_lef

  
end