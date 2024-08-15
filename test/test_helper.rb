ENV["RAILS_ENV"] ||= "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

Rails.application.load_seed
Rails.logger.level = 3

class ActiveSupport::TestCase
  ActiveRecord::Migration.check_pending!
$last_suffix="AAAA"
$last_asset="place-AAAA"

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...
  def create_test_user(params={})
     if !params[:callsign] then 
       params[:callsign]="ZL4"+$last_suffix
       $last_suffix=$last_suffix.next
     end
     if !params[:password] then params[:password]="test" end
     if !params[:password_confirmation] then params[:password_confirmation]="test" end

     user=User.create(params)
  end

  def create_callsign(user, params={})
   if !params[:from_date] then params[:from_date]="1900-01-01" end
   
   if !params[:callsign] then
     params[:callsign]="ZL4"+$last_suffix
     $last_suffix=$last_suffix.next
   end
   params[:user_id]=user.id
 
   uc=UserCallsign.create(params)
  end

  def create_test_asset(params={})
     if !params[:asset_type] then params[:asset_type]="hut" end
     if !params[:minor] then params[:minor]=false end
     if !params[:is_active] then params[:is_active]=true end
     if !params[:name] then 
        params[:name]=$last_asset
        $last_asset=$last_asset.next
     end 

     asset=Asset.create(params)
     asset
  end

  def create_test_log(user, params={})
     if !params[:date] then params[:date]==Time.now() end
     if !params[:callsign1] then params[:callsign1]=user.callsign end
     if !params[:user1_id] then params[:user1_id]=user.id end 
     if !params[:asset_codes] then params[:asset_codes]=[] end 
     log=Log.create(params)
     log
  end

  def create_test_contact(user1, user2, params={})
    if !params[:asset1_codes] then params[:asset1_codes]=[] end
    if !params[:asset2_codes] then params[:asset2_codes]=[] end
    if !params[:time] then params[:time]=Time.now end
    if !params[:date] then params[:date]=params[:time] end
    if !params[:callsign1] then params[:callsign1]=user1.callsign end
    if !params[:callsign2] then params[:callsign2]=user2.callsign end
    params[:user1_id]=user1.id
    params[:user2_id]=user2.id

    contact=Contact.create(params)
    contact
  end
end
