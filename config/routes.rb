Hota::Application.routes.draw do
root 'static_pages#home'
  get "password_resets/new"
  get "password_resets/edit"
  get "password_reset/new"
  get "password_reset/edit"

get "proxy" => "proxy#get", :as => "proxy"

match '/about',   to: 'static_pages#about',   via: 'get'
match '/spots',   to: 'static_pages#spots',   via: 'get'
match '/alerts',   to: 'static_pages#alerts',   via: 'get'
resources :sessions, only: [:new, :create, :destroy]
resources :qsl, only: [:show]
match "/users/editgrid", :to => "users#editgrid", :via => "get"
match "/users/data", :to => "users#data", :as => "user_data", :via => "get"
match "/users/db_action", :to => "users#db_action", :as => "user_db_action", :via => "get"
resources :users
resources :pota_logs
match "/pota_logs/:id/send", :to => "pota_logs#send_email", :as => "send_log", :via => "get"

match "/contacts/check", :to => "contacts#check", :via => "get"
match "/contacts/select", :to => "contacts#select", :via => "get"
match "/contacts/select2", :to => "contacts#select2", :via => "get"
match "/contacts/new2", :to => "contacts#new2", :via => "get"
match "/contacts/editgrid", :to => "contacts#editgrid", :via => "get"
match "/contacts/data", :to => "contacts#data", :as => "contacts_data", :via => "get"
match "/contacts/db_action", :to => "contacts#db_action", :as => "contacts_db_action", :via => "get"

match "/contacts/editgrid", :to => "contacts#editgrid", :via => "get"
match "/contacts/data", :to => "contacts#data", :as => "contact_data", :via => "get"
match "/contacts/db_action", :to => "contacts#db_action", :as => "contact_db_action", :via => "get"
resources :contacts
match "/contest_logs/data", :to => "contest_logs#data", :as => "contest_log_data", :via => "get"
match "/contest_logs/db_action", :to => "contest_logs#db_action", :as => "contest_log_db_action", :via => "get"
match "/contest_logs/:id/save", :to => "contest_logs#save", :as => "contest_log_save_data", :via => "post"
match "/contest_logs/:id/load", :to => "contest_logs#load", :as => "contest_log_load_data", :via => "get"
resources :contest_logs

match "/huts/editgrid", :to => "huts#editgrid", :via => "get"
match "/huts/data", :to => "huts#data", :as => "hut_data", :via => "get"
match "/huts/db_action", :to => "huts#db_action", :as => "hut_db_action", :via => "get"
resources :huts
resources :summits

match "/parks/editgrid", :to => "parks#editgrid", :via => "get"
match "/parks/data", :to => "parks#data", :as => "park_data", :via => "get"
match "/parks/db_action", :to => "parks#db_action", :as => "park_db_action", :via => "get"
resources :parks
resources :islands
resources :contest_series
resources :contests
resources :awards

  match '/sessions', to: 'static_pages#home',    via:'get'
  match '/signin',  to: 'sessions#new',         via: 'get'
  match '/signup',  to: 'users#new',         via: 'get'
  match '/signout', to: 'sessions#destroy',     via: 'delete'
  resources :password_resets, only: [:new, :create, :edit, :update]
  match '/styles.js', to: "maps#styles", via: 'get', as: "styles", defaults: { format: "js" }
  match 'layerswitcher', to: "maps#layerswitcher", via: 'get'
  match '/legend', to: "maps#legend", via: 'get'


resources :query, only: [:index]
resources :querypark, only: [:index]
resources :queryisland, only: [:index]

end

