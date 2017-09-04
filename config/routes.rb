Rails.application.routes.draw do
  
  get   "/manuallef" => "rlm_licenses#index", as: :lef
  post  "/manuallef" => "rlm_licenses#read", as: :read_lef
  
end