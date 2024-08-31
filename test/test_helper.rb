ENV["RAILS_ENV"] ||= "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

Rails.application.load_seed
Rails.logger.level = 3

class ActiveSupport::TestCase
  ActiveRecord::Migration.check_pending!
$last_suffix="AAAA"
$last_asset="place-AAAA"
$last_asset_code=1

Region.create(sota_code: 'CB', name: "Canterbury") 
Region.create(sota_code: 'OT', name: "Otago")
District.create(district_code: 'CC', name: "Christchurch", region_code: "CB")
District.create(district_code: 'WA', name: "Waimate", region_code: "CB")
District.create(district_code: 'DU', name: "Dunedin", region_code: "OT") 
District.create(district_code: 'CO', name: "Central Otago", region_code: "OT")
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
     if params[:is_active]==nil then params[:is_active]=true end
     if !params[:name] then 
        params[:name]=$last_asset
        $last_asset=$last_asset.next
     end 
     if params[:code_prefix] then
        params[:code]=params[:code_prefix]+$last_asset_code.to_s.rjust(3, '0') 
        $last_asset_code=$last_asset_code+1
        params.delete(:code_prefix)
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
    if !params[:time] then params[:time]=Time.now() end
    if !params[:date] then params[:date]=params[:time] end
    if !params[:callsign1] then params[:callsign1]=user1.callsign end
    if !params[:callsign2] then params[:callsign2]=user2.callsign end
    params[:user1_id]=user1.id
    params[:user2_id]=user2.id

    contact=Contact.create(params)
    contact
  end

  def create_test_external_activation(user1, asset1, params={})
    if !params[:date] then params[:date]=Time.now() end
    if !params[:callsign] then params[:callsign]=user1.callsign end
    if !params[:summit_code] then params[:summit_code]=asset1.code end
    if !params[:asset_type] then params[:asset_type]=asset1.asset_type end
    if !params[:qso_count] then params[:qso_count]=1 end
    params[:user_id]=user1.id

    activation=SotaActivation.create(params)
    activation
  end

  def create_test_external_chase(activation,user2, asset1, params={})
    if !params[:time] then params[:time]=Time.now end
    if !params[:date] then params[:date]=params[:time] end
    if !params[:callsign] then params[:callsign]=user2.callsign end
    if !params[:summit_code] then params[:summit_code]=asset1.code end
    if !params[:asset_type] then params[:asset_type]=asset1.asset_type end
    if !params[:asset_type] then params[:asset_type]=asset1.asset_type end
    if !params[:band] then params[:band]='7MHz' end
    if !params[:mode] then params[:mode]='SSB' end
    if !params[:sota_activation_id] then params[:sota_activation_id]=activation.sota_activation_id end
    params[:user_id]=user2.id

    chase=SotaChase.create(params)
    chase
  end
end
