class ApiController < ApplicationController
include PostsHelper

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

    if not params[:is_active] then
      whereclause="is_active is true"
    end

    if not params[:minor] then
      whereclause+=" and minor is not true"
    end

    if params[:asset_type] and params[:asset_type]!='' and params[:asset_type]!='all' then
      asset_type=params[:asset_type]
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


    @assets=Asset.find_by_sql [ "select id, asset_type, code, name,location,minor,is_active,region,created_at, updated_at,old_code,area from assets where "+whereclause ] 

    respond_to do |format|
      format.js { render json: @assets.to_json()}
      format.html { render json: @assets.to_json()}
      format.csv { send_data asset_to_csv(@assets), filename: "assets-#{Date.today}.csv" }
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


end
