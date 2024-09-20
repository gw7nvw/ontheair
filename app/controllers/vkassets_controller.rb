class VkassetsController < ApplicationController
  def index_prep

    whereclause="true"

    asset_type=params[:type]

    if params[:asset_type] and params[:asset_type][:to_s] and params[:asset_type][:to_s]!='' and params[:asset_type][:to_s]!='All' then
      asset_type=safe_param(params[:asset_type][:to_s])
    end

    if asset_type then
      whereclause+=" and award = '"+asset_type+"'"
    end

    if !asset_type or asset_type=="" then asset_type='All' end
    @asset_type=asset_type

    @searchtext=safe_param(params[:searchtext] || "")
    if params[:searchtext] and params[:searchtext]!="" then
       whereclause=whereclause+" and (unaccent(lower(name)) like '%%"+@searchtext.downcase+"%%' or lower(code) like '%%"+@searchtext.downcase+"%%')"
    end

    @assets=VkAsset.find_by_sql [ 'select id,name,code,award,state,wwff_code,pota_code from vk_assets where id in (select id from vk_assets where '+whereclause+' order by name limit 100) order by name' ]
    counts=VkAsset.find_by_sql [ 'select count(id) as id from vk_assets where '+whereclause ]
    #counts=0;
    if counts and counts.first then @count=counts.first.id else @count=0 end

  end

  def index

    if params[:id] then redirect_to '/vkassets/'+params[:id].gsub('/','_')
    else

    @parameters=params_to_query

    index_prep()
    respond_to do |format|
      format.html
      format.js
      format.csv { send_data asset_to_csv(VkAsset.all), filename: "assets-#{Date.today}.csv" }
    end
    end
  end

  def show
    @parameters=params_to_query
    code=(params[:id]||"").gsub("_","/")
    code=code.upcase
    @asset = VkAsset.find_by(code: code)
    if(@asset==nil) then
        if(@asset==nil) then
          flash[:error]="Sorry - "+code+" does not exist in our database"
          redirect_to '/vkassets'
          return true
        end
    end
  end

end
