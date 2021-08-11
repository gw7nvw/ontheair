class ApiController < ApplicationController
include PostsHelper

require 'rexml/document'

skip_before_filter :verify_authenticity_token

def index

end

def assettype
    respond_to do |format|
      format.js { render json: AssetType.all.to_json}
      format.html { render json: AssetType.all.to_json}
      format.csv { send_data asset_to_csv(AssetType.all), filename: "assettypes-#{Date.today}.csv" }
    end
end

def assetlink
  if params[:id] then
    id=params[:id].upcase.gsub('_','/')
    if params[:children] then
      respond_to do |format|
        format.js { render json: AssetLink.where(child_code: id).to_json }
        format.html { render json: AssetLink.where(child_code: id).to_json }
        format.csv { send_data asset_to_csv(AssetLink.where(child_code: id)), filename: "assetlinks-#{Date.today}.csv" }
      end
    else
      respond_to do |format|
        format.js { render json: AssetLink.where(parent_code: id).to_json }
        format.html { render json: AssetLink.where(parent_code: id).to_json }
        format.csv { send_data asset_to_csv(AssetLink.where(parent_code: id)), filename: "assetlinks-#{Date.today}.csv" }
      end
    end

  elsif params[:asset_type] and params[:children] then
    assetLinks=AssetLink.find_by_sql [ " select al.* from asset_links al inner join assets a on a.code = al.child_code where a.asset_type='#{params[:asset_type]}'; " ] 
    respond_to do |format|
      format.js { render json: assetLinks.to_json }
      format.html { render json: assetLinks.to_json }
      format.csv { send_data asset_to_csv(assetLinks), filename: "assetlinks-#{Date.today}.csv" }
    end

  elsif params[:asset_type]
    assetLinks=AssetLink.find_by_sql [ " select al.* from asset_links al inner join assets a on a.code = al.parent_code where a.asset_type='#{params[:asset_type]}'; " ] 
    respond_to do |format|
      format.js { render json: assetLinks.to_json }
      format.html { render json: assetLinks.to_json }
      format.csv { send_data asset_to_csv(assetLinks), filename: "assetlinks-#{Date.today}.csv" }
    end

  else
    respond_to do |format|
      format.js { render json: AssetLink.all.to_json}
      format.html { render json: AssetLink.all.to_json}
      format.csv { send_data asset_to_csv(AssetLink.all), filename: "assetlinks-#{Date.today}.csv" }
    end
  end
end

def asset
    whereclause="true"
    base_filename="assets"

    if not params[:is_active] then
      whereclause="is_active is true"
    end

    if not params[:minor] then
      whereclause+=" and minor is not true"
    end

    if params[:asset_type] and params[:asset_type]!='' and params[:asset_type]!='all' then
      asset_type=params[:asset_type]
      base_filename=params[:asset_type].strip
    end

    if params[:updated_since] then 
      whereclause+=" and updated_at > '"+params[:updated_since]+"'"
    end

    if asset_type then
      whereclause+=" and asset_type = '"+asset_type+"'"
    end

    @searchtext=params[:searchtext] || ""
    if params[:searchtext] then
       whereclause=whereclause+" and (lower(name) like '%%"+@searchtext.downcase+"%%' or lower(code) like '%%"+@searchtext.downcase+"%%')"
    end

    @assets=Asset.find_by_sql [ "select id, url, asset_type, code, name,location,altitude,minor,is_active,region,created_at, updated_at,old_code,area from assets where "+whereclause ] 

    respond_to do |format|
      format.js { render json: @assets.to_json()}
      format.html { render json: @assets.to_json()}
      format.csv { send_data asset_to_csv(@assets), filename: "#{base_filename}-#{Date.today}.csv" }
      format.gpx { send_data asset_to_gpx(@assets), filename: "#{base_filename}-#{Date.today}.gpx" }
    end

end

 def asset_to_csv(items)
      require 'csv'
      csvtext=""
      if items and items.first then
        columns=[]; items.first.attributes.each_pair do |name, value| if !name.include?("password") and !name.include?("digest") and !name.include?("token") and !name.include?("_link") then columns << name end end
        csvtext << columns.to_csv
        items.each do |item|
           fields=[]; item.attributes.each_pair do |name, value| if !name.include?("password") and !name.include?("digest") and !name.include?("token") and !name.include?("_link") then fields << value end end
           csvtext << fields.to_csv
        end
     end
     csvtext
  end

def logs_post

  if api_authenticate(params) then
     res={success: true, message: 'Thanks for the data!'} 
     @upload=Upload.new
     @upload.doc=params[:item][:file]
     res=@upload.save
     puts res
     logfile=File.read(@upload.doc.path)
     logs=Log.import(logfile, nil)
     @upload.destroy
  else
     res={success: false, message: 'Login failed using supplied credentials'}
  end


  respond_to do |format|
    format.js { render json: res.to_json}
    format.html { render json: res.to_json}
  end
end

private

  def upload_params
    params.require(:item).permit(:file)
  end

def api_authenticate(params)
  valid=false
  if params[:item][:userID] and params[:item][:APIKey] then
    user=User.find_by(callsign: params[:item][:userID].upcase)
    if user and user.pin.upcase==params[:item][:APIKey].upcase then 
       valid=true
    else
       #authenticate via PnP 
       #if not a local user, or is a local user and have allowed PnP logins
       #if !user or (user and user.allow_pnp_login==true) then
       if (user and user.allow_pnp_login==true) then
         params={"actClass"=>"WWFF", "actCallsign"=>"test", "actSite"=>"test", "mode"=>"SSB", "freq"=>"7.095", "comments"=>"Test", "userID"=>params[:item][:userID], "APIKey"=>params[:item][:APIKey]} 
         res=send_spot_to_pnp(params,'/DEBUG')
         if res.body.match('Success') then 
           valid=true
           puts "AUTH: SUCCESS authenticated via PnP"
         else
           puts "AUTH: FAILED authentication via PnP"
         end
       end
    end
  end
  valid
end


def asset_to_gpx(assets)
   xml = REXML::Document.new
   gpx = xml.add_element 'gpx', {'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
     'xmlns' => 'http://www.topografix.com/GPX/1/0',
     'xsi:schemaLocation' => 'http://www.topografix.com/GPX/1/0 http://www.topografix.com/GPX/1/0/gpx.xsd',
     'version' => '1.0', 'creator' => 'http://routeguides.co.nz/'}

   assets.each do |a|
     if a.location then
       wpt = gpx.add_element 'wpt'
       wpt.add_element('url').add REXML::Text.new('https://ontheair.nz/'+a.url)
       wpt.add_attributes({'lat' => a.location.y.to_s, 'lon' => a.location.x.to_s})
       wpt.add_element('ele').add(REXML::Text.new(a.altitude.to_s))
       wpt.add_element('name').add(REXML::Text.new(a.name+" ("+a.code+")"+if(a.r_field('points')) then " ["+a.r_field('points').to_s+"]" else "" end))
     end
   end

   xml
end
end
