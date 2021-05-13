require 'resque/server'

Hota::Application.routes.draw do
root 'static_pages#home'
  get "password_resets/new"
  get "password_resets/edit"
  get "password_reset/new"
  get "password_reset/edit"
mount Resque::Server.new, at: "/resque"

get "proxy" => "proxy#get", :as => "proxy"

match '/about',   to: 'static_pages#about',   via: 'get'
match '/results',   to: 'static_pages#results',   via: 'get'
match '/spots',   to: 'static_pages#spots',   via: 'get'
match '/alerts',   to: 'static_pages#alerts',   via: 'get'
resources :sessions, only: [:new, :create, :destroy]
resources :asset_web_links, only: [:create]
resources :asset_links, only: [:create]
get 'asset_web_links/:id/delete', to: 'asset_links#delete'
get 'asset_links/:id/delete', to: 'asset_links#delete'
resources :qsl, only: [:show]
resources :users
resources :posts, only: [:new, :create, :show, :edit, :update]
get 'posts/:id/delete', to: 'posts#delete'
match '/queries/asset', to: 'queries#asset',    via:'get'

resources :sota_logs
resources :pota_logs
match "/pota_logs/:id/send", :to => "pota_logs#send_email", :as => "send_log", :via => "get"
resources :wwff_logs
match "/wwff_logs/:id/send", :to => "wwff_logs#send_email", :as => "wwff_send_log", :via => "get"

match "/logs/:id/save", :to => "logs#save", :as => "log_save_data", :via => "post"
match "/logs/:id/load", :to => "logs#load", :as => "log_load_data", :via => "get"
resources :logs
 get 'logs/:id/delete', to: 'logs#delete'

match "/contacts/:id/editlog", :to => "logs#editcontact", :via => "get"
resources :contacts

resources :assets
match "/assets/:id/associations", :to => "assets#associations", :via => "get"
resources :huts
resources :summits
resources :parks
resources :islands

  match '/sessions', to: 'static_pages#home',    via:'get'
  match '/signin',  to: 'sessions#new',         via: 'get'
  match '/signup',  to: 'users#new',         via: 'get'
  match '/signout', to: 'sessions#destroy',     via: 'delete'
  resources :password_resets, only: [:new, :create, :edit, :update]
  match '/styles.js', to: "maps#styles", via: 'get', as: "styles", defaults: { format: "js" }
  match 'layerswitcher', to: "maps#layerswitcher", via: 'get'
  match '/legend', to: "maps#legend", via: 'get'


resources :query, only: [:index]

end

