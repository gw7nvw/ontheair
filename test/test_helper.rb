# typed: true

ENV["RAILS_ENV"] ||= "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

Rails.application.load_seed
Rails.logger = Logger.new(STDOUT)
Rails.logger.level = 3

class ActiveSupport::TestCase
  ActiveRecord::Migration.check_pending!
$last_suffix="AAAA"
$last_asset="place-AAAA"
$last_asset_code=1
$last_ext_act_id=1
NEWS_TOPIC=4
SPOT_TOPIC=35
ALERT_TOPIC=1

Region.destroy_all
Region.create(dxcc: 'ZL', sota_code: 'CB', name: "Canterbury", boundary: 'MULTIPOLYGON(((171 -40, 174 -40, 174 -41, 171 -41)))') 
Region.create(dxcc: 'ZL', sota_code: 'OT', name: "Otago", boundary: 'MULTIPOLYGON(((171 -41, 174 -41, 174 -42, 171 -42)))')
District.destroy_all
District.create(dxcc: 'ZL', district_code: 'CC', name: "Christchurch", region_code: "CB", boundary: 'MULTIPOLYGON(((171 -40, 173 -40, 173 -41, 171 -41)))')
District.create(dxcc: 'ZL', district_code: 'WA', name: "Waimate", region_code: "CB", boundary: 'MULTIPOLYGON(((173 -40, 174 -40, 174 -41, 173 -41)))')
District.create(dxcc: 'ZL', district_code: 'DU', name: "Dunedin", region_code: "OT",boundary: 'MULTIPOLYGON(((171 -41, 173 -41, 173 -42, 171 -42)))') 
District.create(dxcc: 'ZL', district_code: 'CO', name: "Central Otago", region_code: "OT",boundary: 'MULTIPOLYGON(((173 -41, 174 -41, 174 -42, 173 -42)))')
NzTribalLand.destroy_all
NzTribalLand.create({ "ogc_fid"=>21, "wkb_geometry"=> "MULTIPOLYGON (((170 -40, 175 -40, 175 -35, 170 -35)))", "name"=>"Ngāti Apa"})
NzTribalLand.create({ "ogc_fid"=>20, "wkb_geometry"=> "MULTIPOLYGON (((170 -40, 175 -40, 175 -45, 170 -45)))", "name"=>"Ngāi Tahu"})
Band.create({"meter_band"=>"2190m", "freq_band"=>"136kHz", "group"=>"MF", "min_frequency"=>0.136, "max_frequency"=>0.137})
Band.create({"meter_band"=>"560m", "freq_band"=>"501kHz", "group"=>"MF", "min_frequency"=>0.501, "max_frequency"=>0.504})
Band.create({"meter_band"=>"60m", "freq_band"=>"5MHz", "group"=>"HF", "min_frequency"=>5.351, "max_frequency"=>5.367})
Band.create({"meter_band"=>"40m", "freq_band"=>"7MHz", "group"=>"HF", "min_frequency"=>7.0, "max_frequency"=>7.3})
Band.create({"meter_band"=>"30m", "freq_band"=>"10MHz", "group"=>"HF", "min_frequency"=>10.1, "max_frequency"=>10.15})
Band.create({"meter_band"=>"20m", "freq_band"=>"14MHz", "group"=>"HF", "min_frequency"=>14.0, "max_frequency"=>14.35})
Band.create({"meter_band"=>"17m", "freq_band"=>"18MHz", "group"=>"HF", "min_frequency"=>18.068, "max_frequency"=>18.168})
Band.create({"meter_band"=>"15m", "freq_band"=>"21MHz", "group"=>"HF", "min_frequency"=>21.0, "max_frequency"=>21.45})
Band.create({"meter_band"=>"12m", "freq_band"=>"24MHz", "group"=>"HF", "min_frequency"=>24.89, "max_frequency"=>24.99})
Band.create({"meter_band"=>"11m", "freq_band"=>"27MHz", "group"=>"HF", "min_frequency"=>26.95, "max_frequency"=>27.3})
Band.create({"meter_band"=>"10m", "freq_band"=>"28MHz", "group"=>"HF", "min_frequency"=>28.0, "max_frequency"=>29.7})
Band.create({"meter_band"=>"6m", "freq_band"=>"50MHz", "group"=>"VHF", "min_frequency"=>50.0, "max_frequency"=>54.0})
Band.create({"meter_band"=>"4m", "freq_band"=>"70MHz", "group"=>"VHF", "min_frequency"=>70.0, "max_frequency"=>71.0})
Band.create({"meter_band"=>"2m", "freq_band"=>"144MHz", "group"=>"VHF", "min_frequency"=>144.0, "max_frequency"=>148.0})
Band.create({"meter_band"=>"1.25m", "freq_band"=>"220MHz", "group"=>"VHF", "min_frequency"=>222.0, "max_frequency"=>225.0})
Band.create({"meter_band"=>"70cm", "freq_band"=>"430MHz", "group"=>"UHF", "min_frequency"=>420.0, "max_frequency"=>450.0})
Band.create({"meter_band"=>"33cm", "freq_band"=>"900MHz", "group"=>"UHF", "min_frequency"=>902.0, "max_frequency"=>928.0})
Band.create({"meter_band"=>"23cm", "freq_band"=>"1.24GHz", "group"=>"UHF", "min_frequency"=>1240.0, "max_frequency"=>1300.0})
Band.create({"meter_band"=>"13cm", "freq_band"=>"2.3GHz", "group"=>"UHF", "min_frequency"=>2300.0, "max_frequency"=>2450.0})
Band.create({"meter_band"=>"9cm", "freq_band"=>"3.4GHz", "group"=>"microwave", "min_frequency"=>3300.0, "max_frequency"=>3500.0})
Band.create({"meter_band"=>"6cm", "freq_band"=>"5.7GHz", "group"=>"microwave", "min_frequency"=>5650.0, "max_frequency"=>5925.0})
Band.create({"meter_band"=>"3cm", "freq_band"=>"10GHz", "group"=>"microwave", "min_frequency"=>10000.0, "max_frequency"=>10500.0})
Band.create({"meter_band"=>"1.25cm", "freq_band"=>"24GHz", "group"=>"microwave", "min_frequency"=>24000.0, "max_frequency"=>24250.0})
Band.create({"meter_band"=>"6mm", "freq_band"=>"47GHz", "group"=>"microwave", "min_frequency"=>47000.0, "max_frequency"=>47250.0})
Band.create({"meter_band"=>"4mm", "freq_band"=>"76GHz", "group"=>"microwave", "min_frequency"=>75500.0, "max_frequency"=>81000.0})
Band.create({"meter_band"=>"2.5mm", "freq_band"=>"122GHz", "group"=>"microwave", "min_frequency"=>119980.0, "max_frequency"=>120020.0})
Band.create({"meter_band"=>"2mm", "freq_band"=>"146GHz", "group"=>"microwave", "min_frequency"=>142000.0, "max_frequency"=>149000.0})
Band.create({"meter_band"=>"1mm", "freq_band"=>"248GHz", "group"=>"microwave", "min_frequency"=>241000.0, "max_frequency"=>250000.0})
Band.create({"meter_band"=>"160m", "freq_band"=>"1.8MHz", "group"=>"HF", "min_frequency"=>1.8, "max_frequency"=>2.0})
Band.create({"meter_band"=>"80m", "freq_band"=>"3.6MHz", "group"=>"HF", "min_frequency"=>3.5, "max_frequency"=>4.0})

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  def create_test_spot(user, params={})
     if !params[:callsign] then params[:callsign]=user.callsign end
     if !params[:user1_id] then params[:created_by_id]=user.id end
     if !params[:user1_id] then params[:updated_by_id]=user.id end
     if !params[:referenced_date] then params[:referenced_date]=Time.now().to_date end
     if !params[:referenced_time] then params[:referenced_time]=Time.now() end
     topic_id=SPOT_TOPIC

     post=Post.create(params)
     item=Item.create(topic_id: topic_id, item_type: 'post', item_id: post.id, created_at: post.created_at, created_by_id: params[:created_by_id], updated_by_id: params[:created_by_id])
     item.reload
  end

  def create_test_external_spot(user, params={})
     if !params[:callsign] then params[:callsign]=user.callsign end
     if !params[:activatorCallsign] then params[:activatorCallsign]=user.callsign end
     if !params[:time] then params[:time]=Time.now() end

     spot=ExternalSpot.create(params)
  end
  def create_test_alert(user, params={})
     if !params[:callsign] then params[:callsign]=user.callsign end
     if !params[:user1_id] then params[:created_by_id]=user.id end
     if !params[:referenced_date] then params[:referenced_date]=Time.now() end
     if !params[:referenced_time] then params[:referenced_time]=Time.now() end
     topic_id=ALERT_TOPIC

     post=Post.create(params)
     item=Item.create(topic_id: topic_id, item_type: 'post', item_id: post.id, created_at: post.created_at, created_by_id: params[:created_by_id])
     item.reload
  end

  def create_test_photo(user, asset, title, description)
     image=File.open("#{Rails.root}/test/fixtures/files/image/test.jpeg")
     photo=Image.create(title: title, description: description, image: image)
     pal=AssetPhotoLink.create(asset_code: asset.code, photo_id: photo.id, link_url: photo.image.url(:original))
  end

  def create_test_post(topic_id, title, contents, createdAt=Time.now())
     post=Post.create(title: title, description: contents)
     item=Item.create(topic_id: topic_id, item_type: 'post', item_id: post.id, created_at: createdAt)
     item.reload
  end

  def create_test_web_link(asset, link, link_class)
     AssetWebLink.create(asset_code: asset.code, url: link, link_class: link_class)
  end

  def create_test_comment(user, asset, comment)
     Comment.create(code: asset.code, comment: comment, updated_by_id: user.id)
  end

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
   if !params[:from_date] then params[:from_date]="1900-01-01".to_date end
   
   if !params[:callsign] then
     params[:callsign]="ZL4"+$last_suffix
     $last_suffix=$last_suffix.next
   end
   params[:user_id]=user.id
 
   uc=UserCallsign.create(params)
  end

  def create_point(x,y)
    factory = RGeo::Geographic.spherical_factory(srid: 4326)

    latlon = factory.point(x, y)
  end

  def create_test_vkasset(params={})
    if !params[:name] then
      params[:name]=$last_asset
      $last_asset=$last_asset.next
    end

    if params[:code_prefix] then
      params[:code]=params[:code_prefix]+$last_asset_code.to_s.rjust(3, '0')
      $last_asset_code=$last_asset_code+1
      params.delete(:code_prefix)
    end

    asset=VkAsset.create(params)
    asset.reload
  end

  def create_test_asset(params={})
     if !params[:asset_type] then params[:asset_type]="hut" end
     if !params[:minor] then params[:minor]=false end
     if params[:is_active]==nil then params[:is_active]=true end
     if params[:country]==nil then params[:country]='ZL' end
     if !params[:name] then 
        params[:name]=$last_asset
        $last_asset=$last_asset.next
     end 
     if params[:code_prefix] then
        params[:code]=params[:code_prefix]+$last_asset_code.to_s.rjust(3, '0') 
        $last_asset_code=$last_asset_code+1
        params.delete(:code_prefix)
     end
     if params[:test_radius] then 
       radius=params[:test_radius]
       params.delete(:test_radius)
       x=params[:location].x
       y=params[:location].y
       params[:boundary]="MULTIPOLYGON(((#{x+radius} #{y+radius}, #{x+radius} #{y-radius}, #{x-radius} #{y-radius}, #{x-radius} #{y+radius})))"
     end

     asset=Asset.create(params)
     asset.reload
  end

  def create_test_log(user, params={})
     if !params[:date] then params[:date]=Time.now() end
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
    if !params[:external_activation_id] then params[:external_activation_id]=$last_ext_act_id; $last_ext_act_id+=1 end
    params[:user_id]=user1.id

    activation=ExternalActivation.create(params)
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
    if !params[:external_activation_id] then params[:external_activation_id]=activation.external_activation_id end
    params[:user_id]=user2.id

    chase=ExternalChase.create(params)
    chase
  end

  def get_table_test(body,id)
    body=body.split(/id="#{id}">/)[1]
    if body then body=body.split('</table>')[0]  end
    #handle case where id was on div and we still have opening table
    if body and body["<table"] then body=body.split(/<table(?:.*?)>/)[1] end
    body
  end

  def get_adif_lines(body)
    lines=body.split('<eor>')
  end

  def get_adif_param(line, tag)
    text=line.split('<'+tag)[1]
    text=text.split('>')[1]
    text=text.split('<')[0]
  end

  def get_row_test(body,number)
    rows=body.split('<tr>')
    row=rows[number]
    row=row.split('</tr>')[0]
  end
  def get_row_count_test(body)
    if body then
      rows=body.split('<tr>')
      rows.count-1
    else
      0
    end
  end

  def get_col_test(body,number)
    rows=body.split(/<td(?:.*?)>/)
    row=rows[number]
    row=row.split('</td>')[0]
  end
 
  def make_regex_safe(text)
   text=text.gsub("[","\\[").gsub("]","\\]").gsub("{","\\{").gsub("}","\\}").gsub("(","\\(").gsub(")","\\)").gsub(":","\\:") 
   text
  end
end
