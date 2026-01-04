# typed: false
require 'resque/server'

Hota::Application.routes.draw do
#resque
mount Resque::Server.new, at: "/resque"

#static pages
root 'static_pages#home'
match '/results',   to: 'static_pages#results',   via: 'get'
match '/recent',   to: 'static_pages#recent',   via: 'get'
match '/spots',   to: 'static_pages#spots',   via: 'get'
match '/alerts',   to: 'static_pages#alerts',   via: 'get'
match '/admin_stats',   to: 'static_pages#admin_stats',   via: 'get'
match '/ack_news',   to: 'static_pages#ack_news',   via: 'get'

resources :asset_links, only: [:create]
get 'asset_links/:id/delete', to: 'asset_links#delete'

resources :asset_web_links, only: [:create]
get 'asset_web_links/:id/delete', to: 'asset_web_links#delete'

resources :assets, only: [:index, :show, :edit, :new, :create, :update]
match "/assets/:id/associations", :to => "assets#associations", :via => "get"
get 'assets/:id/refresh_sota', to: 'assets#refresh_sota'
get 'assets/:id/refresh_pota', to: 'assets#refresh_pota'

resources :awards, only: [:index, :show, :edit, :new, :create, :update]

resources :callsigns, only: [:create, :edit, :update]
get 'callsigns/:id/delete', to: 'callsigns#delete'
patch 'callsigns/:id', to: 'callsigns#update'

resources :comments
get 'comments/:id/delete', to: 'comments#delete'

resources :contacts, only: [:index, :show, :new, :create]
match "/contacts/:id/editlog", :to => "logs#editcontact", :via => "get"
match "/contacts/:id/confirm", :to => "contacts#confirm", :via => "get"
match "/contacts/:id/refute", :to => "contacts#refute", :via => "get"

resources :districts, only: [:index, :show]

match "/hema_logs/chaser/submit", :to => "hema_logs#submit_chaser", :as => "hema_submit_chaser_log", :via => "get"
match "/hema_logs/chaser", :to => "hema_logs#chaser", :as => "hema_chaser_log", :via => "get"
resources :hema_logs, only: [:index, :show]
match "/hema_logs/:id/submit", :to => "hema_logs#submit", :as => "hema_send_log", :via => "get"
match "/hema_logs/:id/delete", :to => "hema_logs#delete", :as => "hema_delete_log", :via => "get"
match "/hema_logs/:id/finalise", :to => "hema_logs#finalise", :as => "hema_finalise_log", :via => "get"

#controller no longer used - delete handled in photos
#get 'images/:id/delete', to: 'images#delete'

get 'logs/upload', to: 'logs#upload' #log uploads
post 'logs/upload', to: 'logs#savefile' #log uploads
resources :logs
get 'logs/:id/delete', to: 'logs#delete'
match "/logs/:id/save", :to => "logs#save", :as => "log_save_data", :via => "post" #spreadsheet editor
match "/logs/:id/load", :to => "logs#load", :as => "log_load_data", :via => "get" #spreadsheet editor

#maps
match 'layerswitcher', to: "maps#layerswitcher", via: 'get'
match 'updatelayers', to: "maps#updatelayers", via: 'get'
match '/legend', to: "maps#legend", via: 'get'

#asset class redirects
get "humps", to: 'assets#index', defaults: {type: 'hump'}
get "lighthouses", to: 'assets#index', defaults: {type: 'lighthouse'}
get "wwff", to: 'assets#index', defaults: {type: 'wwff park'}
get "pota", to: 'assets#index', defaults: {type: 'pota park'}
get "summits", to: 'assets#index', defaults: {type: 'summit'}
get "parks", to: 'assets#index', defaults: {type: 'park'}
get "islands", to: 'assets#index', defaults: {type: 'island'}
get "huts", to: 'assets#index', defaults: {type: 'hut'}
get "lakes", to: 'assets#index', defaults: {type: 'lake'}

get "proxy" => "proxy#get", :as => "proxy"

match '/sitemap.xml', to: 'sitemaps#index', via: 'get', as: "sitemap", defaults: { format: "xml" }

resources :sessions, only: [:new, :create, :destroy]
# resources :qsl, only: [:show] #not currently active

resources :users
get 'users/:id/assets', to: 'users#assets'
get 'users/:id/test_notification', to: 'users#test_notification'
get 'users/:id/awards', to: 'users#awards'
get 'users/:id/region_progress', to: 'users#region_progress'
get 'users/:id/district_progress', to: 'users#district_progress'
get 'users/:id/p2p', to: 'users#p2p'
get 'users/:id/add', to: 'users#add'
get 'users/:id/delete', to: 'users#delete'
get 'users/:id/set_external', to: 'users#update_external'
match '/signup',  to: 'users#new',         via: 'get'

resources :posts, only: [:new, :create, :show, :edit, :update]
get 'posts/:id/delete', to: 'posts#delete'

resources :photos, only: [:new, :create, :show, :edit, :update]
get 'photos/:id/delete', to: 'photos#delete'

resources :topics, only: [:index, :new, :create, :show, :edit, :update]

#match '/queries/asset', to: 'queries#asset',    via:'get'
resources :query, only: [:index]
match '/query_location', to: 'query#location',    via:'get'

resources :api, only: [:index]
match '/api/assets', to: 'api#asset',    via:'get'
match '/api/assettypes', to: 'api#assettype',    via:'get'
match '/api/assetlinks', to: 'api#assetlink',    via:'get'
match '/api/logs', to: 'api#logs_post',    via:'post'
match '/api/spots', to: 'api#spot_post',    via:'post'
match '/api/spots', to: 'api#spot',    via:'get'

resources :sota_logs

resources :pota_logs
match "/pota_logs/:id/send", :to => "pota_logs#send_email", :as => "send_log", :via => "get"
match "/pota_logs/:id/download", :to => "pota_logs#download", :as => "download_log", :via => "get"

resources :wwff_logs
match "/wwff_logs/:id/send", :to => "wwff_logs#send_email", :as => "wwff_send_log", :via => "get"
match "/wwff_logs/:id/download", :to => "wwff_logs#download", :as => "wwff_download_log", :via => "get"

resources :vkassets

resources :regions

resources :geology, only: [:index, :show]

match '/sessions', to: 'static_pages#home',    via:'get'
match '/signin',  to: 'sessions#new',         via: 'get'
match '/signout', to: 'sessions#destroy',     via: 'delete'

resources :password_resets, only: [:new, :create, :edit, :update]
get "password_resets/new"
get "password_resets/edit"
get "password_reset/new"
get "password_reset/edit"



end

