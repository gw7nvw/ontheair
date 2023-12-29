require 'resque/server'

Hota::Application.routes.draw do
root 'static_pages#home'
  get "password_resets/new"
  get "password_resets/edit"
  get "password_reset/new"
  get "password_reset/edit"
mount Resque::Server.new, at: "/resque"

get "proxy" => "proxy#get", :as => "proxy"

match '/sitemap.xml', to: 'sitemaps#index', via: 'get', as: "sitemap", defaults: { format: "xml" }

match '/about',   to: 'static_pages#about',   via: 'get'
match '/help',   to: 'static_pages#help',   via: 'get'
match '/faq',   to: 'static_pages#faq',   via: 'get'
match '/results',   to: 'static_pages#results',   via: 'get'
match '/recent',   to: 'static_pages#recent',   via: 'get'
match '/spots',   to: 'static_pages#spots',   via: 'get'
match '/alerts',   to: 'static_pages#alerts',   via: 'get'
match '/ack_news',   to: 'static_pages#ack_news',   via: 'get'
resources :callsigns
get 'callsigns/:id/delete', to: 'callsigns#delete'
patch 'callsigns/:id', to: 'callsigns#update'
resources :sessions, only: [:new, :create, :destroy]
resources :asset_web_links, only: [:create]
resources :awards
resources :comments
get 'comments/:id/delete', to: 'comments#delete'
resources :asset_links, only: [:create]
get 'asset_web_links/:id/delete', to: 'asset_web_links#delete'
get 'asset_links/:id/delete', to: 'asset_links#delete'
resources :qsl, only: [:show]
resources :users
get 'users/:id/assets', to: 'users#assets'
get 'users/:id/awards', to: 'users#awards'
get 'users/:id/region_progress', to: 'users#region_progress'
get 'users/:id/district_progress', to: 'users#district_progress'
get 'users/:id/p2p', to: 'users#p2p'
get 'users/:id/add', to: 'users#add'
get 'users/:id/delete', to: 'users#delete'
get 'images/:id/delete', to: 'images#delete'
get 'photos/:id/delete', to: 'photos#delete'

resources :posts, only: [:new, :create, :show, :edit, :update]
resources :photos, only: [:new, :create, :show, :edit, :update]
resources :topics, only: [:index, :new, :create, :show, :edit, :update]
get 'posts/:id/delete', to: 'posts#delete'
match '/queries/asset', to: 'queries#asset',    via:'get'
resources :api, only: [:index]
match '/api/assets', to: 'api#asset',    via:'get'
match '/api/assettypes', to: 'api#assettype',    via:'get'
match '/api/assetlinks', to: 'api#assetlink',    via:'get'
match '/api/logs', to: 'api#logs_post',    via:'post'

resources :sota_logs
resources :pota_logs
match "/pota_logs/:id/send", :to => "pota_logs#send_email", :as => "send_log", :via => "get"
match "/pota_logs/:id/download", :to => "pota_logs#download", :as => "download_log", :via => "get"
resources :wwff_logs
match "/wwff_logs/:id/send", :to => "wwff_logs#send_email", :as => "wwff_send_log", :via => "get"

match "/logs/:id/save", :to => "logs#save", :as => "log_save_data", :via => "post"
match "/logs/:id/load", :to => "logs#load", :as => "log_load_data", :via => "get"
 get 'logs/upload', to: 'logs#upload'
 post 'logs/upload', to: 'logs#savefile'
resources :logs
 get 'logs/:id/delete', to: 'logs#delete'

match "/contacts/:id/editlog", :to => "logs#editcontact", :via => "get"
resources :contacts

resources :assets
resources :vkassets
resources :districts
resources :regions
match "/assets/:id/associations", :to => "assets#associations", :via => "get"
resources :huts
resources :summits
resources :parks
resources :islands

  get 'assets/:id/refresh_sota', to: 'assets#refresh_sota'
  get 'assets/:id/refresh_pota', to: 'assets#refresh_pota'
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

